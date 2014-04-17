#
# Cookbook Name:: mongodb
# Definition:: mongodb
#
# Copyright 2011, edelight GmbH
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

# ensure parents exist
class Chef
  class ResourceDefinitionList
  end
end

class Chef::ResourceDefinitionList::MongoDB
  def self.configure_replicaset(node, name, members)
    # lazy require, to move loading this modules to runtime of the cookbook
    require 'rubygems'
    require 'mongo'

    if members.length == 0
      fail ArgumentError, "Cannot configure replicaset '#{name}', no member nodes found"
    end

    connection = make_slave_connection 'localhost', node['mongodb']['port']

    # ensure the node originating the connection is be included in the replicaset
    members << node unless members.any? { |m| m.name == node.name }
    # sort by name to ensure member ids are the same between runs
    members.sort! { |x, y| x.name <=> y.name }

    replicaset_config = ReplicasetConfig.new name

    members.each do
      replicaset_config << ReplicasetMember.new(member)
    end

    Chef::Log.info("Configuring replicaset with config #{replicaset_config.inspect}")

    result = initiate_replicaset(connection, replicaset_config)

    if ok? result
      # everything is fine, do nothing
    elsif result.fetch('errmsg', nil) =~ /(\S+) is already initiated/ ||
          result.fetch('errmsg', nil) == 'already initialized'
      # replicaset is initialized, requires reconfig

      # retrieve host to from errmsg
      match = Regexp.last_match
      server, port = if match.nil? || match.length < 2
                       ['localhost', node['mongodb']['port']]
                     else
                       match[1].split(':')
                     end

      connection = make_slave_connection server, port

      # check if both configs are the same
      current_config = connection['local']['system']['replset'].find_one('_id' => name)

      if replicaset_config.matches? current_config
        # config is up-to-date, do nothing
        Chef::Log.info("Replicaset '#{name}' already configured")
      elsif replicaset_config.matches_by_ipaddress? config
        # config is up-to-date, but ips are used instead of hostnames, change config to hostnames
        Chef::Log.info("Need to convert ips to hostnames for replicaset '#{name}'")
        intended_config = ReplicasetConfig.from_config current_config
        intended_config.incr
        intended_config.replace_member_hosts_with_fqdns_from replicaset_config

        connection = make_replset_connection old_members

        result = nil
        begin
          result = connection.replicaset_config intended_config, :check_response => false
        rescue Mongo::ConnectionFailure
          # reconfiguring destroys existing connections, reconnect
          connection = Mongo::Connection.new('localhost', node['mongodb']['config']['port'], :op_timeout => 5, :slave_ok => true)
          config = connection['local']['system']['replset'].find_one('_id' => name)
          # Validate configuration change
          if config['members'] == replicaset_config.member_list
            Chef::Log.info("New config successfully applied: #{config.inspect}")
          else
            Chef::Log.error("Failed to apply new config. Current config: #{config.inspect} Target config #{replicaset_config.member_list}")
            return
          end
        end
        unless ok? result
          fail "configuring replicaset returned: #{result.inspect}"
        end
      else
        # remove removed members from the replicaset and add the new ones

        current_config = config
        old_members = current_config['members'].collect{ |m| m['host'] }

        intended_config = ReplicasetConfig.from_config(current_config)
        intended_config.incr
        intended_config.remove_members_absent_from replicaset_config
        intended_config.update_member_attributes_while_keeping_ids_from replicaset_config
        intended_config.add_members_adjuct_to replicaset_config

        connection = make_replset_connection old_members

        result = nil
        begin
          result = connection.replicaset_config intended_config, :check_response => false
        rescue Mongo::ConnectionFailure
          # reconfiguring destroys existing connections, reconnect
          connection = Mongo::Connection.new('localhost', node['mongodb']['config']['port'], :op_timeout => 5, :slave_ok => true)
          config = connection['local']['system']['replset'].find_one('_id' => name)

          current_config = ReplicasetConfig.from_config config
          if replicaset_config.matches? current_config
            Chef::Log.debug("New config successfully applied: #{current_config.inspect}")
          else
            fail "Failed to apply new config. "\
                 "Current config: #{current_config.inspect} "\
                 "Target config: #{replicaset_config.inspect}"
          end
        end
        unless result.nil? || result.fetch('errmsg', nil).nil?
          fail "Failed to configure replicaset, reason: #{result.inspect}"
        end
      end
    else
      fail "Failed to configure replicaset, reason: #{result.inspect}"
    end
  end

  def self.configure_shards(node, shard_nodes)
    # lazy require, to move loading this modules to runtime of the cookbook
    require 'rubygems'
    require 'mongo'

    shard_groups = Hash.new { |h, k| h[k] = [] }

    shard_nodes.each do |n|
      if n['recipes'].include?('mongodb::replicaset')
        # do not include hidden members when calling addShard
        # see https://jira.mongodb.org/browse/SERVER-9882
        next if n['mongodb']['replica_hidden']
        key = "rs_#{n['mongodb']['shard_name']}"
      else
        key = '_single'
      end
      shard_groups[key] << "#{n['fqdn']}:#{n['mongodb']['config']['port']}"
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

    begin
      connection = Mongo::Connection.new('localhost', node['mongodb']['config']['port'], :op_timeout => 5)
    rescue => e
      Chef::Log.warn("Could not connect to database: 'localhost:#{node['mongodb']['config']['port']}', reason #{e}")
      return
    end

    admin = connection['admin']

    shard_members.each do |shard|
      cmd = BSON::OrderedHash.new
      cmd['addShard'] = shard
      begin
        result = admin.command(cmd, :check_response => false)
      rescue Mongo::OperationTimeout
        result = "Adding shard '#{shard}' timed out, run the recipe again to check the result"
      end
      Chef::Log.info(result.inspect)
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

    connection = make_connection 'localhost', node['mongodb']['port']

    databases = sharded_collections.keys.map { |x| x.split('.').first }.uniq
    Chef::Log.info("enable sharding for these databases: '#{databases.inspect}'")

    databases.each do |db_name|
      begin
        result = connection.enable_sharding(db_name, :check_response => false)
      rescue Mongo::OperationTimeout
        fail "enable sharding for '#{db_name}' timed out, run the recipe again to check the result"
      end
      if ok? result
        # success
        Chef::Log.info("Enabled sharding for database '#{db_name}'")
      else
        # some error
        errmsg = result.fetch('errmsg')
        if errmsg == 'already enabled'
          Chef::Log.debug("Sharding is already enabled for database '#{db_name}', doing nothing")
        else
          fail "Failed to enable sharding for database #{db_name}, result was: #{result.inspect}"
        end
      end
    end

    sharded_collections.each do |name, key|
      begin
        result = connection.shard_collection name, key, :check_response => false
      rescue Mongo::OperationTimeout
        fail "sharding '#{name}' on key '#{key}' timed out, run the recipe again to check the result"
      end
      if ok? result
        # success
        Chef::Log.info("Sharding for collection '#{result['collectionsharded']}' enabled")
      else
        # some error
        errmsg = result.fetch('errmsg')
        if errmsg == 'already sharded'
          Chef::Log.debug("Sharding is already configured for collection '#{name}', doing nothing")
        else
          fail "Failed to shard collection #{name}, result was: #{result.inspect}"
        end
      end
    end
  end

  # Ensure retry upon failure using constant backoff
  def self.rescue_connection_failure(max_retries = 30)
    # TODO: investigate truncated binary exponential backoff
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

  def self.initiate_replicaset(connection, replicaset_config)
    admin = connection['admin']
    cmd = BSON::OrderedHash.new
    cmd['replSetInitiate'] = replicaset_config.to_config

    result = nil
    begin
      result = admin.command(cmd, :check_response => false)
    rescue Mongo::OperationTimeout
      fail 'Timed out configuring the replicaset, this will take some time, another run should run smoothly'
    end
    result
  end


  def self.reconfigure_replicaset(connection, replicaset_config)
    admin = connection['admin']

    result = nil
    begin
      result = admin.replicaset_config config, :check_response => false
    rescue Mongo::ConnectionFailure
      # reconfiguring destroys exisiting connections, reconnect
      connection = Mongo::Connection.new('localhost', node['mongodb']['port'], :op_timeout => 5, :slave_ok => true)
      config = connection['local']['system']['replset'].find_one('_id' => name)

      current_config = ReplicasetConfig.from_config config
      if replicaset_config.matches? current_config
        Chef::Log.debug("New config successfully applied: #{current_config.inspect}")
      else
        fail "Failed to apply new config. "\
             "Current config: #{current_config.inspect} "\
             "Target config: #{replicaset_config.inspect}"
      end
    end
    unless result.nil? || result.fetch('errmsg', nil).nil?
      fail "Failed to configure replicaset, reason: #{result.inspect}"
    end
    result
  end

  def self.make_slave_connection(host,port)
    connection = nil
    rescue_connection_failure do
      connection = Mongo::Connection.new(host, port, :op_timeout => 5, :slave_ok => true)
      connection.database_names # check connection
    end
  end

  def self.make_read_connection(host,port)
    connection = nil
    rescue_connection_failure do
      connection = Mongo::Connection.new(host, port, :op_timeout => 5)
      connection.database_names # check connection
    end
  end

  def self.make_replset_connection(hosts)
    rs_connection = nil
    rescue_connection_failure do
      rs_connection = Mongo::ReplSetConnection.new(hosts)
      rs_connection.database_names # check connection
    end
    rs_connection
  end

  def ok?(doc)
    Mongo::Support.ok? doc
  end
end

module ConfigurationCommands

  def replicaset_reconfigure(config, opts = {})
    raise MongoArgumentError, "config must be a document" unless config.class == Hash
    cmd = BSON::OrderedHash.new
    cmd['replSetReconfig'] = config

    @db.command(cmd, command_opts(opts))
  end


  def shard_collection(collection, key, opts = {})
    raise MongoArgumentError, "collection must be a string" unless collection.class == String
    raise MongoArgumentError, "key must be a string" unless key.class == String
    cmd = BSON::OrderedHash.new
    cmd['shardcollection'] = collection
    cmd['key'] = { key => 1 }

    @db.command(cmd, command_opts(opts))
  end

  def enable_sharding(db_name, opts = {})
    cmd = BSON::OrderedHash.new
    cmd['enablesharding'] = db_name
    @db.command(cmd, command_opts(opts))
  end
end


module Mongo
  class Connection
    extend ConfigurationCommands
  end
end
