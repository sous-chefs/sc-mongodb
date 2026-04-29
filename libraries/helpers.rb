# frozen_string_literal: true

require 'yaml'

module ScMongoDB
  module Helpers
    module Config
      module_function

      def compact_hash(config)
        config.each_with_object({}) do |(key, value), new_hash|
          if value.is_a?(Hash)
            compacted = compact_hash(value)
            new_hash[key] = compacted unless compacted.empty?
          else
            new_hash[key] = value unless value.nil? || value == ''
          end
        end
      end

      def to_yaml_options(config)
        YAML.dump(compact_hash(config.to_hash))
      end
    end

    module Defaults
      def mongodb_user
        platform_family?('rhel', 'fedora', 'amazon') ? 'mongod' : 'mongodb'
      end

      def mongodb_group
        mongodb_user
      end

      def mongodb_root_group
        'root'
      end

      def mongodb_db_path
        platform_family?('rhel', 'fedora', 'amazon') ? '/var/lib/mongo' : '/var/lib/mongodb'
      end

      def mongodb_package_options
        platform_family?('debian') ? '-o Dpkg::Options::="--force-confold"' : nil
      end

      def mongodb_sasl_dev_package
        platform_family?('rhel', 'fedora', 'amazon') ? 'cyrus-sasl-devel' : 'libsasl2-dev'
      end

      def mongodb_default_config(type, port, bind_ip)
        config = {
          'net' => {
            'port' => port,
            'bindIp' => bind_ip,
          },
          'systemLog' => {
            'destination' => 'file',
            'logAppend' => true,
            'path' => type == 'mongos' ? '/var/log/mongodb/mongos.log' : '/var/log/mongodb/mongod.log',
          },
        }

        unless type == 'mongos'
          config['storage'] = {
            'dbPath' => mongodb_db_path,
            'engine' => 'wiredTiger',
          }
          config['replication'] = {}
          config['security'] = {}
        end

        config['sharding'] = {} if type == 'mongos'
        config
      end

      def mongodb_deep_merge(left, right)
        left.merge(right) do |_key, old_value, new_value|
          old_value.is_a?(Hash) && new_value.is_a?(Hash) ? mongodb_deep_merge(old_value, new_value) : new_value
        end
      end

      def mongodb_agent_package_url(type)
        base = 'https://cloud.mongodb.com/download/agent'

        case node['platform_family']
        when 'amazon', 'fedora', 'rhel'
          package = type == 'automation' ? 'mongodb-mms-automation-agent-manager-latest.x86_64.rhel7.rpm' : "mongodb-mms-#{type}-agent-latest.x86_64.rpm"
          "#{base}/#{type}/#{package}"
        when 'debian'
          package = type == 'automation' ? 'mongodb-mms-automation-agent-manager_latest_amd64.ubuntu1604.deb' : "mongodb-mms-#{type}-agent_latest_amd64.ubuntu1604.deb"
          "#{base}/#{type}/#{package}"
        end
      end

      def mongodb_agent_config(type, api_key)
        config = { 'mmsApiKey' => api_key }

        case type
        when 'automation'
          config.merge(
            'mmsBaseUrl' => 'https://mms.mongodb.com',
            'logFile' => '/var/log/mongodb-mms-automation/automation-agent.log',
            'mmsConfigBackup' => '/var/lib/mongodb-mms-automation/mms-cluster-config-backup.json',
            'logLevel' => 'INFO',
            'maxLogFiles' => 10,
            'maxLogFileSize' => 268_435_456
          )
        when 'backup'
          config.merge(
            'mothership' => 'api-backup.mongodb.com',
            'https' => true
          )
        else
          config.merge('mmsBaseUrl' => 'https://mms.mongodb.com')
        end
      end
    end

    module Cluster
      module_function

      def cluster_up_to_date?(from_server, expected)
        cut_down = from_server.map do |server|
          other = expected.find { |entry| server['_id'] == entry['_id'] }
          server.select { |key, _value| other&.key?(key) }
        end

        cut_down == expected
      end

      def create_replicaset_member(member)
        return {} if member['fqdn'].to_s.match?(/\.vagrantup\.com$/)

        port = member.dig('mongodb', 'config', 'mongod', 'net', 'port') || 27_017
        host = member.dig('mongodb', 'use_ip_address') ? member['ipaddress'] : member['fqdn']
        result = { 'host' => "#{host}:#{port}" }

        result['arbiterOnly'] = true if member.dig('mongodb', 'replica_arbiter_only')
        result['buildIndexes'] = false if member.dig('mongodb', 'replica_build_indexes') == false
        result['hidden'] = true if member.dig('mongodb', 'replica_hidden')
        result['slaveDelay'] = member.dig('mongodb', 'replica_slave_delay') if member.dig('mongodb', 'replica_slave_delay').to_i.positive?

        priority = if result['buildIndexes'] == false || result['hidden'] || result['slaveDelay']
                     0
                   else
                     member.dig('mongodb', 'replica_priority') || 1
                   end
        result['priority'] = priority unless priority == 1

        tags = member.dig('mongodb', 'replica_tags') || {}
        result['tags'] = tags unless tags.empty?

        votes = member.dig('mongodb', 'replica_votes') || 1
        result['votes'] = votes unless votes == 1

        result.freeze
      end

      def configure_replicaset(local_node, name, members)
        require 'mongo'

        local_member = local_node.to_hash
        members = [local_member] if members.empty?
        rs_members = members.each_with_index.map { |member, index| create_replicaset_member(member).merge('_id' => index) }.select { |member| member.key?('host') }
        port = local_node.dig('mongodb', 'config', 'mongod', 'net', 'port') || 27_017
        client = Mongo::Client.new(["localhost:#{port}"], server_selection_timeout: 5)
        admin = client.use('admin')
        result = admin.command(replSetInitiate: { '_id' => name, 'members' => rs_members }).documents.first
        Chef::Log.info("MongoDB replicaset #{name} configure result: #{result.inspect}")
      rescue Mongo::Error::OperationFailure => e
        Chef::Log.info("MongoDB replicaset #{name} not changed: #{e.message}")
      rescue Mongo::Error => e
        Chef::Log.warn("Could not configure MongoDB replicaset #{name}: #{e.message}")
      ensure
        client&.close
      end

      def configure_shards(port, shard_members, sharded_collections)
        require 'mongo'

        client = Mongo::Client.new(["localhost:#{port}"], server_selection_timeout: 5)
        admin = client.use('admin')

        shard_members.each do |shard|
          result = admin.command(addShard: shard).documents.first
          Chef::Log.info("MongoDB addShard #{shard} result: #{result.inspect}")
        rescue Mongo::Error::OperationFailure => e
          Chef::Log.info("MongoDB shard #{shard} not changed: #{e.message}")
        end

        sharded_collections.keys.map { |collection| collection.split('.').first }.uniq.each do |database|
          admin.command(enablesharding: database)
        rescue Mongo::Error::OperationFailure => e
          Chef::Log.info("MongoDB sharding database #{database} not changed: #{e.message}")
        end

        sharded_collections.each do |collection, key|
          admin.command(shardcollection: collection, key: { key => 1 })
        rescue Mongo::Error::OperationFailure => e
          Chef::Log.info("MongoDB sharded collection #{collection} not changed: #{e.message}")
        end
      rescue Mongo::Error => e
        Chef::Log.warn("Could not configure MongoDB sharding: #{e.message}")
      ensure
        client&.close
      end
    end

    module User
      def user_exists_v2?(username, connection)
        connection['system.users'].find(user: username).any?
      end

      def add_user_v2(username, password, database, roles = [])
        connection = authenticated_client
        db = connection.use(database)

        if user_exists_v2?(username, connection)
          Chef::Log.info("#{username} already exists on #{database}")
        else
          db.database.users.create(username, password: password, roles: roles)
          Chef::Log.info("Created user #{username} on #{database}")
        end
      ensure
        connection&.close
      end

      def delete_user_v2(username, database)
        connection = authenticated_client
        db = connection.use(database)

        if user_exists_v2?(username, connection)
          db.database.users.remove(username)
          Chef::Log.info("Deleted user #{username} on #{database}")
        else
          Chef::Log.info("User #{username} does not exist on #{database}")
        end
      ensure
        connection&.close
      end

      def authenticated_client(attempt = 0)
        config = new_resource.connection
        host = config['host'] || 'localhost'
        port = config['port'] || 27_017
        auth = config['authentication'] || {}
        options = {
          connect_timeout: 5,
          socket_timeout: 5,
          server_selection_timeout: 3,
        }
        options[:user] = auth['username'] if auth['username']
        options[:password] = auth['password'] if auth['password']

        client = Mongo::Client.new(["#{host}:#{port}"], options)
        client.database_names
        client
      rescue Mongo::Error::NoServerAvailable, Mongo::Error::OperationFailure
        retries = config.dig('user_management', 'connection', 'retries') || 2
        delay = config.dig('user_management', 'connection', 'delay') || 2
        raise if attempt >= retries

        sleep(delay)
        authenticated_client(attempt + 1)
      end
    end
  end
end
