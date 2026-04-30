# frozen_string_literal: true

provides :mongodb_replicaset
unified_mode true

property :replicaset_name, String, name_property: true
property :members, Array, default: []
property :auto_configure, [true, false], default: true
property :version, [String, Float], default: '8.0'
property :package_version, [String, nil]
property :config, Hash, default: {}
property :port, Integer, default: 27_017
property :bind_ip, String, default: '0.0.0.0'
property :ruby_gems, Hash, default: { 'mongo' => '~> 2.0' }

default_action :create

action :create do
  mongodb_ruby_gems 'replicaset gems' do
    gems new_resource.ruby_gems
    action :install
  end

  mongodb_instance 'mongod' do
    mongodb_type 'mongod'
    version new_resource.version
    package_version new_resource.package_version
    config new_resource.config
    port new_resource.port
    bind_ip new_resource.bind_ip
    replicaset true
    replicaset_name new_resource.replicaset_name
    action :create
  end

  ruby_block "configure MongoDB replicaset #{new_resource.replicaset_name}" do
    block do
      ScMongoDB::Helpers::Cluster.configure_replicaset(node, new_resource.replicaset_name, new_resource.members)
    end
    action :run
    only_if { new_resource.auto_configure }
  end
end

action :delete do
  mongodb_instance 'mongod' do
    action :delete
  end
end
