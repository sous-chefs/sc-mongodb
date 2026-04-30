# frozen_string_literal: true

provides :mongodb_instance
unified_mode true

use '_partial/_instance'

property :install, [true, false], default: true
property :service_actions, Array, default: [:enable, :start]
property :replicaset_name, [String, nil]
property :replicaset, [true, false], default: false
property :shard, [true, false], default: false
property :configservers, Array, default: []
property :data_path, [String, nil]
property :key_file_content, [String, nil], sensitive: true

default_action :create

action :create do
  mongodb_install new_resource.instance_name do
    version new_resource.version
    package_name new_resource.package_name
    package_version new_resource.package_version
    action :install
    only_if { new_resource.install }
  end

  mongodb_config new_resource.instance_name do
    mongodb_type service_type
    port new_resource.port
    bind_ip new_resource.bind_ip
    config effective_config
    config_path effective_config_path
    data_path new_resource.data_path
    key_file_content new_resource.key_file_content
    user new_resource.user
    group new_resource.group
    root_group new_resource.root_group
    action :create
  end

  mongodb_service new_resource.instance_name do
    mongodb_type service_type
    config_path effective_config_path
    user new_resource.user
    group new_resource.group
    service_actions new_resource.service_actions
    action :create
  end
end

action :delete do
  mongodb_service new_resource.instance_name do
    action :delete
  end

  mongodb_config new_resource.instance_name do
    mongodb_type service_type
    config_path effective_config_path
    data_path new_resource.data_path
    key_file_content new_resource.key_file_content
    action :delete
  end

  mongodb_install new_resource.instance_name do
    package_name new_resource.package_name
    action :remove
    only_if { new_resource.install }
  end
end

action_class do
  include ScMongoDB::Helpers::Defaults

  def service_type
    new_resource.mongodb_type == 'mongos' ? 'mongos' : 'mongod'
  end

  def effective_config_path
    new_resource.config_path || (service_type == 'mongos' ? '/etc/mongos.conf' : '/etc/mongod.conf')
  end

  def effective_config
    config = mongodb_deep_merge(mongodb_default_config(service_type, new_resource.port, new_resource.bind_ip), new_resource.config)

    if new_resource.mongodb_type == 'configserver'
      config['sharding'] ||= {}
      config['sharding']['clusterRole'] = 'configsvr'
    elsif new_resource.shard
      config['sharding'] ||= {}
      config['sharding']['clusterRole'] = 'shardsvr'
    elsif service_type == 'mongos'
      config.delete('storage')
      config['sharding'] ||= {}
      config['sharding']['configDB'] ||= configserver_hosts unless new_resource.configservers.empty?
    end

    if new_resource.replicaset || new_resource.replicaset_name
      config['replication'] ||= {}
      config['replication']['replSetName'] ||= new_resource.replicaset_name || 'rs_default'
    end

    config
  end

  def configserver_hosts
    new_resource.configservers.map do |configserver|
      host = configserver['mongodb'] && configserver['mongodb']['configserver_url'] ? configserver['mongodb']['configserver_url'] : configserver['fqdn']
      port = configserver.dig('mongodb', 'config', 'mongod', 'net', 'port') || 27_017
      "#{host}:#{port}"
    end.sort.join(',')
  end
end
