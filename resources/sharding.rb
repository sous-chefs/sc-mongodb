# frozen_string_literal: true

provides :mongodb_sharding
unified_mode true

property :sharding_name, String, name_property: true
property :role, String, equal_to: %w(configserver shard mongos), default: 'mongos'
property :cluster_name, [String, nil]
property :shard_name, String, default: 'default'
property :version, [String, Float], default: '8.0'
property :package_version, [String, nil]
property :config, Hash, default: {}
property :port, Integer, default: 27_017
property :bind_ip, String, default: '0.0.0.0'
property :replicaset_name, [String, nil]
property :configservers, Array, default: []
property :shards, Array, default: []
property :sharded_collections, Hash, default: {}
property :auto_configure, [true, false], default: true
property :ruby_gems, Hash, default: { 'mongo' => '~> 2.0' }

default_action :create

action :create do
  case new_resource.role
  when 'configserver'
    mongodb_instance 'mongod' do
      mongodb_type 'configserver'
      version new_resource.version
      package_version new_resource.package_version
      config new_resource.config
      port new_resource.port
      bind_ip new_resource.bind_ip
      action :create
    end
  when 'shard'
    mongodb_instance 'mongod' do
      mongodb_type 'mongod'
      version new_resource.version
      package_version new_resource.package_version
      config new_resource.config
      port new_resource.port
      bind_ip new_resource.bind_ip
      shard true
      replicaset !new_resource.replicaset_name.nil?
      replicaset_name new_resource.replicaset_name
      action :create
    end
  when 'mongos'
    mongodb_ruby_gems 'sharding gems' do
      gems new_resource.ruby_gems
      action :install
    end

    mongodb_instance 'mongos' do
      mongodb_type 'mongos'
      version new_resource.version
      package_version new_resource.package_version
      config new_resource.config
      port new_resource.port
      bind_ip new_resource.bind_ip
      configservers new_resource.configservers
      action :create
    end

    ruby_block "configure MongoDB sharding #{new_resource.sharding_name}" do
      block do
        ScMongoDB::Helpers::Cluster.configure_shards(new_resource.port, new_resource.shards, new_resource.sharded_collections)
      end
      action :run
      only_if { new_resource.auto_configure }
    end
  end
end

action :delete do
  mongodb_instance(new_resource.role == 'mongos' ? 'mongos' : 'mongod') do
    action :delete
  end
end
