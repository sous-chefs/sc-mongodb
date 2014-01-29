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

require 'json'

# helper to cast any object to a boolean
def Boolean(obj) # rubocop:disable MethodName
  obj ? true : false
end

# ensure parents exist
class Chef
  class ResourceDefinitionList
  end
end

class Chef::ResourceDefinitionList::MongoDB
  # ReplicasetMember is a support class to convert a node object into a
  # MongoDB replicaset member document.
  #
  # This implementation maps document keys onto values from the node
  # object, and requires each to exist:
  #
  #    host:          "{node.fqdn}:{node.mongodb.config.port}"
  #    arbiterOnly:   node.mongodb.replica_arbiter_only
  #    buildIndexes:  node.mongodb.replica_build_indexes
  #    hidden:        node.mongodb.replica_hidden
  #    slaveDelay:    node.mongodb.replica_slave_delay
  #    priority:      node.mongodb.replica_priority
  #    tags:          node.mongodb.replica_tags
  #    votes:         node.mongodb.replica_votes
  #
  # Originally this would not send entries if they matched the defaults:
  #
  #    arbiterOnly:   false
  #    buildIndexes:  true
  #    hidden:        false
  #    slaveDelay:    0
  #    priority:      1
  #    tags:          {}
  #    votes:         1
  class ReplicasetMember
    attr_accessor :node, :id

    def initialize(node, id = nil)
      @node = node
      @id = id
    end

    def fqdn
      node['fqdn']
    end

    def mongodb_port
      mongodb['config']['port']
    end

    def fqdn_host
      "#{fqdn}:#{mongodb_port}"
    end

    def ipaddress_host
      "#{ipaddress}:#{mongodb_port}"
    end

    def host
      fqdn_host
    end

    def arbiter_only
      Boolean(mongodb['replica_arbiter_only'])
    end

    def build_indexes
      Boolean(mongodb['replica_build_indexes'])
    end

    def hidden
      Boolean(mongodb['replica_hidden'])
    end

    def slave_delay
      Integer(mongodb['replica_slave_delay'])
    end

    # priority must be 0 if the member lacks buildIndexes, is hidden or
    # has slaveDelay
    def priority
      if !build_indexes || hidden || slave_delay
        # must not become primary
        priority = 0
      else
        priority = mongodb['replica_priority']
      end
      priority
    end

    def ipaddress
      node['ipaddress']
    end

    def tags
      mongodb['replica_tags'].to_hash
    end

    def votes
      Integer(mongodb['replica_votes'])
    end

    def to_h
      hash = {
        'host' =>          host,
        'arbiterOnly' =>   arbiter_only,
        'buildIndexes' =>  build_indexes,
        'hidden' =>        hidden,
        'slaveDelay' =>    slave_delay,
        'priority' =>      priority,
        'tags' =>          tags,
        'votes' =>         votes
      }
      hash['_id'] = id if id
      hash
    end

    def to_h_with_ipaddress
      hash = {
        'host' =>          ipaddress_host
      }
      hash['_id'] = id if id
      hash
    end

    private

    def mongodb
      node['mongodb']
    end
  end

  class ReplicasetConfig
    attr_accessor :name, :members

    def initialize(name, members = {})
      @name = name
      @members = members
    end

    def <<(member)
      members[member.host] = member
    end

    def to_config
      {
        '_id' => name,
        'members' => member_list
      }
    end

    def member_list
      members.values.map(&:to_h)
    end

    def matches?(config)
      config['_id'] == name &&
      config['members'] == member_list
    end

    def matches_by_ipaddress?(config)
      config['_id'] == name &&
      config['members'] == member_list_with_ipaddresses
    end

    def inspect
      "<ReplicasetConfig name=#{name.inspect} members=\"#{members.values.map { |m| m.host }.join(', ')}\">"
    end

    private

    def member_list_with_ipaddresses
      members.values.map(&:to_h_with_ipaddress)
    end
  end

  def self.configure_replicaset(node, name, members)
    # lazy require, to move loading this modules to runtime of the cookbook
    require 'rubygems'
    require 'mongo'

    if members.length == 0
      if Chef::Config[:solo]
        Chef::Log.warn('Cannot search for member nodes with chef-solo, defaulting to single node replica set')
      else
        Chef::Log.warn("Cannot configure replicaset '#{name}', no member nodes found")
        return
      end
    end

    begin
      connection = nil
      rescue_connection_failure do
        connection = Mongo::Connection.new('localhost', node['mongodb']['config']['port'], :op_timeout => 5, :slave_ok => true)
        connection.database_names # check connection
      end
    rescue => e
      Chef::Log.warn("Could not connect to database: 'localhost:#{node['mongodb']['config']['port']}', reason: #{e}")
      return
    end

    # ensure the node originating the connection is be included in the replicaset
    members << node unless members.any? { |m| m.name == node.name }
    # sort by name to ensure member ids are the same between runs
    members.sort! { |x, y| x.name <=> y.name }

    replicaset_config = ReplicasetConfig.new name
    members.each_index do |n|
      member = ReplicasetMember.new(members[n], n)
      replicaset_config << member
    end

    Chef::Log.info("Configuring replicaset with config #{replicaset_config.inspect}")

    result = initiate_replicaset(connection, replicaset_config)

    if result.fetch('ok', nil) == 1
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

      begin
        connection = Mongo::Connection.new(server, port, :op_timeout => 5, :slave_ok => true)
      rescue
        abort("Could not connect to database: '#{server}:#{port}'")
      end

      # check if both configs are the same
      config = connection['local']['system']['replset'].find_one('_id' => name)

      if replicaset_config.matches? config
        # config is up-to-date, do nothing
        Chef::Log.info("Replicaset '#{name}' already configured")
      elsif replicaset_config.matches_by_ipaddress? config
        # config is up-to-date, but ips are used instead of hostnames, change config to hostnames
        Chef::Log.info("Need to convert ips to hostnames for replicaset '#{name}'")
        old_members = config['members'].map { |m| m['host'] }

        # update response members to use host instead of ipaddress
        config['members'] = replicaset_config.member_list
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
          result = admin.command(cmd, :check_response => false)
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
        Chef::Log.error("configuring replicaset returned: #{result.inspect}") unless result.fetch('errmsg', nil).nil?
      else
        # remove removed members from the replicaset and add the new ones
        max_id = config['members'].map { |member| member['_id'] }.max
        rs_member_hosts = replicaset_config.member_list.map { |member| member['host'] }
        config['version'] += 1
        old_members = config['members'].map { |member| member['host'] }
        members_delete = old_members - rs_member_hosts
        config['members'] = config['members'].delete_if { |m| members_delete.include?(m['host']) }
        config['members'].map! do |m|
          host = m['host']
          { '_id' => m['_id'], 'host' => host }.merge(replicaset_config.members[host])
        end
        members_add = rs_member_hosts - old_members
        members_add.each do |m|
          max_id += 1
          config['members'] << { '_id' => max_id, 'host' => m }.merge(replicaset_config.members[m])
        end

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
          result = admin.command(cmd, :check_response => false)
        rescue Mongo::ConnectionFailure
          # reconfiguring destroys existing connections, reconnect
          connection = Mongo::Connection.new('localhost', node['mongodb']['config']['port'], :op_timeout => 5, :slave_ok => true)
          config = connection['local']['system']['replset'].find_one('_id' => name)
          # Validate configuration change
          if config['members'] == rs_member_hosts
            Chef::Log.info("New config successfully applied: #{config.inspect}")
          else
            Chef::Log.error("Failed to apply new config. Current config: #{config.inspect} Target config #{rs_member_hosts}")
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

    begin
      connection = Mongo::Connection.new('localhost', node['mongodb']['config']['port'], :op_timeout => 5)
    rescue => e
      Chef::Log.warn("Could not connect to database: 'localhost:#{node['mongodb']['config']['port']}', reason #{e}")
      return
    end

    admin = connection['admin']

    databases = sharded_collections.keys.map { |x| x.split('.').first }.uniq
    Chef::Log.info("enable sharding for these databases: '#{databases.inspect}'")

    databases.each do |db_name|
      cmd = BSON::OrderedHash.new
      cmd['enablesharding'] = db_name
      begin
        result = admin.command(cmd, :check_response => false)
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
        result = admin.command(cmd, :check_response => false)
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

  def self.initiate_replicaset(connection, replicaset_config)
    admin = connection['admin']
    cmd = BSON::OrderedHash.new
    cmd['replSetInitiate'] = replicaset_config.to_config

    begin
      result = admin.command(cmd, :check_response => false)
    rescue Mongo::OperationTimeout
      msg = 'Started configuring the replicaset, this will take some time, another run should run smoothly'
      Chef::Log.error(msg)
      fail msg # rubocop:disable SignalException
    end
    result
  end
end
