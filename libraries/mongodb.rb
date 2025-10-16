#
# Cookbook:: sc-mongodb
# Definition:: mongodb
#
# Copyright:: 2011, edelight GmbH
# Authors:
#       Markus Korn <markus.korn@edelight.de>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'json'

class Chef::ResourceDefinitionList::MongoDB
  # node['mongodb']['config']['mongod']['net']['port'] required for port
  # if node['mongodb']['use_ip_address']
  #   node['ipaddress'] is required
  # else
  #    node['fqdn'] is required
  # end
  #
  # if node['fqnd'] is a vagrant host, ignore it
  # node['mongodb']['replica_priority'] is required
  #
  def self.cluster_up_to_date?(from_server, expected)
    cut_down = from_server.map do |s|
      other = expected.select { |e| s['_id'] == e['_id'] }.first
      s.select { |k, _v| other.key?(k) }
    end

    cut_down == expected
  end

  def self.create_replicaset_member(node)
    return {} if node['fqdn'] =~ /\.vagrantup\.com$/

    port = node['mongodb']['config']['mongod']['net']['port']
    host = node['mongodb']['use_ip_address'] ? node['ipaddress'] : node['fqdn']
    address = "#{host}:#{port}"

    member = {}
    member['host'] = address
    member['arbiterOnly'] = true if node['mongodb']['replica_arbiter_only']
    member['buildIndexes'] = false unless node['mongodb']['replica_build_indexes']
    member['hidden'] = true if node['mongodb']['replica_hidden']
    slave_delay = node['mongodb']['replica_slave_delay']
    member['slaveDelay'] = slave_delay if slave_delay > 0

    priority = if member['buildIndexes'] == false || member['hidden'] || member['slaveDelay']
                 0
               else
                 node['mongodb']['replica_priority']
               end
    member['priority'] = priority unless priority == 1
    tags = node['mongodb']['replica_tags'].to_hash
    member['tags'] = tags unless tags.empty?
    votes = node['mongodb']['replica_votes']
    member['votes'] = votes unless votes == 1

    member.freeze
  end

  def self.configure_replicaset(node, name, members)
    # lazy require, to move loading this modules to runtime of the cookbook
    require 'rubygems'
    require 'mongo'

    if members.empty? && Chef::Config[:solo]
      Chef::Log.warn('Cannot search for member nodes with chef-solo, defaulting to single node replica set')
    end

    mongo_host = 'localhost'
    mongo_port = node['mongodb']['config']['mongod']['net']['port']

    begin
      connection = nil
      rescue_connection_failure do
        connection = Mongo::Connection.new(mongo_host, mongo_port, op_timeout: 5, slave_ok: true)
        connection.database_names # check connection
      end
    rescue => e
      Chef::Log.warn("Could not connect to database: '#{mongo_host}:#{mongo_port}', reason: #{e}")
      return
    end

    # Want the node originating the connection to be included in the replicaset
    members << node unless members.any? { |m| m.name == node.name }
    members.sort! { |x, y| x.name <=> y.name }

    rs_members = members.each_with_index.map { |member, n| create_replicaset_member(member).merge('_id' => n) }.select { |m| m.key? 'host' }

    Chef::Log.info(
      "Configuring replicaset with members #{members.map { |n| n['hostname'] }.join(', ')}"
    )

    Chef::Log.debug(
      "Configuring replicaset with config: #{rs_members}"
    )

    admin = connection['admin']
    cmd = BSON::OrderedHash.new
    cmd['replSetInitiate'] = {
      '_id' => name,
      'members' => rs_members,
    }

    begin
      result = admin.command(cmd, check_response: false)
    rescue Mongo::OperationTimeout
      Chef::Log.info('Started configuring the replicaset, this will take some time, another run should run smoothly')
      return
    end
    if result.fetch('ok', nil) == 1
      # everything is fine, do nothing
    elsif result.fetch('errmsg', nil) =~ /(\S+) is already initiated/ || \
          result.fetch('errmsg', nil) == 'already initialized' || \
          result.fetch('errmsg', nil) =~ /is not empty on the initiating member/
      mongo_configured_host, mongo_configured_port = \
        Regexp.last_match.nil? || Regexp.last_match.length < 2 ? [mongo_host, mongo_port] : Regexp.last_match[1].split(':')
      begin
        connection = Mongo::Connection.new(mongo_configured_host, mongo_configured_port, op_timeout: 5, slave_ok: true)
      rescue
        abort("Could not connect to database: '#{mongo_host}:#{mongo_port}'")
      end

      rs_member_ips = members.each_with_index.map do |member, n|
        port = member['mongodb']['config']['mongod']['net']['port']
        { '_id' => n, 'host' => "#{member['ipaddress']}:#{port}" }
      end

      # check if both configs are the same
      config = connection['local']['system']['replset'].find_one('_id' => name)
      Chef::Log.debug "Current members are #{config['members']} and we expect #{rs_members}"
      if config && cluster_up_to_date?(config['members'], rs_members)
        # config is up-to-date, do nothing
        Chef::Log.info("Replicaset '#{name}' already configured")
      elsif config['_id'] == name && config['members'] == rs_member_ips
        # config is up-to-date, but ips are used instead of hostnames, change config to hostnames
        Chef::Log.info("Need to convert ips to hostnames for replicaset '#{name}'")
        old_members = config['members'].map { |m| m['host'] }
        mapping = {}
        rs_member_ips.each do |mem_h|
          members.each do |n|
            ip, prt = mem_h['host'].split(':')
            mapping["#{ip}:#{prt}"] = "#{n['fqdn']}:#{prt}" if ip == n['ipaddress']
          end
        end
        config['members'].map! do |m|
          host = mapping[m['host']]
          { '_id' => m['_id'], 'host' => host }.merge(rs_options[host])
        end
        config['version'] += 1

        rs_connection = nil
        rescue_connection_failure do
          rs_connection = Mongo::ReplSetConnection.new(old_members)
          rs_connection.database_names # check connection
        end

        admin = rs_connection['admin']
        cmd = BSON::OrderedHash.new
        cmd['replSetReconfig'] = config
        result = nil
        begin
          result = admin.command(cmd, check_response: false)
        rescue Mongo::ConnectionFailure
          # reconfiguring destroys existing connections, reconnect
          connection = Mongo::Connection.new('localhost', node['mongodb']['config']['port'], op_timeout: 5, slave_ok: true)
          config = connection['local']['system']['replset'].find_one('_id' => name)
          # Validate configuration change
          if config['members'] == rs_members
            Chef::Log.info("New config successfully applied: #{config.inspect}")
          else
            Chef::Log.error("Failed to apply new config. Current config: #{config.inspect} Target config #{rs_members}")
            return
          end
        end
        Chef::Log.error("configuring replicaset returned: #{result.inspect}") unless result.fetch('errmsg', nil).nil?
      else
        Chef::Log.info 'going to update the members of the replicaset'
        old_members = config['members'].dup
        new_members = rs_members.dup
        old_ids = old_members.map { |m| m['_id'] }

        old_members_by_host = old_members.each_with_object({}) { |m, hash| hash[m['host']] = m  }
        new_members_by_host = new_members.each_with_object({}) { |m, hash| hash[m['host']] = m  }

        ids = (0...256).to_a - old_ids

        # use the _id value when present, use a generated one from ids otherwise
        new_members = new_members_by_host.map { |h, m| old_members_by_host.fetch(h, {}).merge(m) }

        new_members.map! { |member| member.merge('_id' => member['_id'] || ids.shift) }

        new_config = config.dup
        new_config['members'] = new_members
        new_config['version'] += 1

        Chef::Log.info "after updating the members, config = #{new_config}"

        rs_connection = nil
        force = false
        rescue_connection_failure do
          case new_members.count
          when 0
            # deletes the replicaset
            force = true
            rs_connection = Mongo::Connection.new(mongo_host, mongo_port, op_timeout: 5, slave_ok: true)
          else
            rs_connection = Mongo::ReplSetConnection.new(old_members.map { |m| m['host'] })
          end
          rs_connection.database_names # check connection
        end

        admin = rs_connection['admin']

        cmd = BSON::OrderedHash.new
        cmd['replSetReconfig'] = new_config

        result = nil
        begin
          result = admin.command(cmd, force: force, check_response: false)
        rescue Mongo::ConnectionFailure
          # reconfiguring destroys existing connections, reconnect
          connection = Mongo::Connection.new(mongo_host, mongo_port, op_timeout: 5, slave_ok: true)
          config = connection['local']['system']['replset'].find_one('_id' => name)
          # Validate configuration change
          if config['members'] == rs_members
            Chef::Log.info("New config successfully applied: #{config.inspect}")
          else
            Chef::Log.error("Failed to apply new config. Current config: #{config.inspect} Target config #{rs_members}")
            return
          end
        end
        Chef::Log.error("configuring replicaset returned: #{result.inspect}") unless result.nil? || result.fetch('errmsg', nil).nil?
      end
    elsif !result.fetch('errmsg', nil).nil?
      Chef::Log.error("Failed to configure replicaset, reason: #{result.inspect}")
    end
  end

  def self.configure_shards(node, shard_nodes)
    # lazy require, to move loading this modules to runtime of the cookbook
    require 'rubygems'
    require 'mongo'

    shard_groups = Hash.new { |h, k| h[k] = [] }

    shard_nodes.each do |n|
      if n['recipes'].include?('sc-mongodb::replicaset')
        # do not include hidden members when calling addShard
        # see https://jira.mongodb.org/browse/SERVER-9882
        next if n['mongodb']['replica_hidden']
        key = n['mongodb']['config']['mongod']['replication']['replSetName'] || "rs_#{n['mongodb']['shard_name']}"
      else
        key = '_single'
      end
      shard_groups[key] << "#{n['fqdn']}:#{n['mongodb']['config']['mongod']['net']['port']}"
    end
    Chef::Log.info(shard_groups.inspect)

    shard_members = []
    shard_groups.each do |name, members|
      if name == '_single'
        shard_members += members
      else
        shard_members << "#{name}/#{members.join(',')}"
      end
    end
    Chef::Log.info(shard_members.inspect)

    mongo_port = node['mongodb']['config']['mongos']['net']['port']

    begin
      connection = nil
      rescue_connection_failure do
        connection = Mongo::Connection.new('localhost', mongo_port, op_timeout: 5)
      end
    rescue => e
      Chef::Log.warn("Could not connect to database: 'localhost:#{mongo_port}', reason #{e}")
      return
    end

    admin = connection['admin']

    # If we require authentication on mongos / mongod, need to authenticate to run these commands
    if node.recipe?('sc-mongodb::user_management')
      begin
        admin.authenticate(node['mongodb']['authentication']['username'], node['mongodb']['authentication']['password'])
      rescue Mongo::AuthenticationError => e
        Chef::Log.warn("Unable to authenticate with database to add shards to mongos node: #{e}")
      end
    end

    shard_members.each do |shard|
      cmd = BSON::OrderedHash.new
      cmd['addShard'] = shard
      require 'pry'
      # binding.pry
      begin
        result = admin.command(cmd, check_response: false)
      rescue Mongo::OperationTimeout
        result = "Adding shard '#{shard}' timed out, run the recipe again to check the result"
      end

      if result['ok'] == 0.0
        Chef::Log.error(result.inspect)
      else
        Chef::Log.info(result.inspect)
      end
    end
  end

  def self.configure_sharded_collections(node, sharded_collections)
    if sharded_collections.nil? || sharded_collections.empty?
      Chef::Log.warn('No sharded collections configured, doing nothing')
      return
    end

    # lazy require, to move loading this modules to runtime of the cookbook
    require 'rubygems'
    require 'mongo'

    mongo_port = node['mongodb']['config']['mongos']['net']['port']

    begin
      connection = nil
      rescue_connection_failure do
        connection = Mongo::Connection.new('localhost', mongo_port, op_timeout: 5)
      end
    rescue => e
      Chef::Log.warn("Could not connect to database: 'localhost:#{mongo_port}', reason #{e}")
      return
    end

    admin = connection['admin']

    # If we require authentication on mongos / mongod, need to authenticate to run these commands
    if node.recipe?('sc-mongodb::user_management')
      begin
        admin.authenticate(node['mongodb']['authentication']['username'], node['mongodb']['authentication']['password'])
      rescue Mongo::AuthenticationError => e
        Chef::Log.warn("Unable to authenticate with database to configure databased on mongos node: #{e}")
      end
    end

    databases = sharded_collections.keys.map { |x| x.split('.').first }.uniq
    Chef::Log.info("enable sharding for these databases: '#{databases.inspect}'")

    databases.each do |db_name|
      cmd = BSON::OrderedHash.new
      cmd['enablesharding'] = db_name
      begin
        result = admin.command(cmd, check_response: false)
      rescue Mongo::OperationTimeout
        result = "enable sharding for '#{db_name}' timed out, run the recipe again to check the result"
      end
      if result['ok'] == 0
        # some error
        errmsg = result.fetch('errmsg')
        if errmsg == 'already enabled'
          Chef::Log.info("Sharding is already enabled for database '#{db_name}', doing nothing")
        else
          Chef::Log.error("Failed to enable sharding for database #{db_name}, result was: #{result.inspect}")
        end
      else
        # success
        Chef::Log.info("Enabled sharding for database '#{db_name}'")
      end
    end

    sharded_collections.each do |name, key|
      cmd = BSON::OrderedHash.new
      cmd['shardcollection'] = name
      cmd['key'] = { key => 1 }
      begin
        result = admin.command(cmd, check_response: false)
      rescue Mongo::OperationTimeout
        result = "sharding '#{name}' on key '#{key}' timed out, run the recipe again to check the result"
      end
      if result['ok'] == 0
        # some error
        errmsg = result.fetch('errmsg')
        if errmsg == 'already sharded'
          Chef::Log.info("Sharding is already configured for collection '#{name}', doing nothing")
        else
          Chef::Log.error("Failed to shard collection #{name}, result was: #{result.inspect}")
        end
      else
        # success
        Chef::Log.info("Sharding for collection '#{result['collectionsharded']}' enabled")
      end
    end
  end

  # Ensure retry upon failure
  def self.rescue_connection_failure(max_retries = 30)
    retries = 0
    begin
      yield
    rescue Mongo::ConnectionFailure => ex
      retries += 1
      raise ex if retries > max_retries
      sleep(0.5)
      retry
    end
  end
end
