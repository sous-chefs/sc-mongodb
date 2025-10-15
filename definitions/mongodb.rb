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

# TODO: This needs to be converted to a custom resource
define :mongodb_instance, # rubocop:disable ChefModernize/Definitions
       mongodb_type: 'mongod',
       action: [:enable, :start],
       logpath: '/var/log/mongodb/mongod.log',
       configservers: [],
       replicaset: nil,
       notifies: [] do
  # TODO: this is the only remain use of params[:mongodb_type], is it still needed?
  unless %w(mongod configserver mongos).include?(params[:mongodb_type])
    raise ArgumentError, ":mongodb_type must be 'mongod', 'configserver' or 'mongos'; was #{params[:mongodb_type].inspect}"
  end

  require 'ostruct'

  new_resource = OpenStruct.new

  # Determine type right away so we know if we need mongos or mognod installation
  new_resource.is_mongos = params[:mongodb_type] == 'mongos'

  # Determine if this will be part of a shard
  new_resource.is_shard = node['mongodb']['is_shard']

  # Make changes to node['mongodb']['config'] before copying to new_resource.
  if new_resource.is_mongos
    provider = 'mongos'
    # mongos will fail to start if dbpath is set
    node.default['mongodb']['config']['mongos']['storage']['dbPath'] = nil

    # Search for config servers
    unless node['mongodb']['config']['mongos']['sharding']['configDB']
      node.default['mongodb']['config']['mongos']['sharding']['configDB'] = params[:configservers].map do |n|
        "#{n['mongodb']['configserver_url'] || n['fqdn']}:#{n['mongodb']['config']['mongod']['net']['port']}"
      end.sort.join(',')

      # TODO: handle 3.2 config server replicasets
      # if node['mongodb']['package_version'].to_f >= 3.2
      #   node.default['mongodb']['config']['sharding']['configDB']
      # end
    end
    new_resource.config = node['mongodb']['config']['mongos'].to_hash
    new_resource.dbconfig_file = node['mongodb']['dbconfig_file']['mongos']
    new_resource.dbpath = nil
    new_resource.sysconfig_file = node['mongodb']['sysconfig_file']['mongos']
    new_resource.sysconfig_vars = node['mongodb']['sysconfig']['mongos']
  else
    provider = 'mongod'
    new_resource.config = node['mongodb']['config']['mongod'].to_hash
    new_resource.replicaset_name = new_resource.config['replication']['replSetName']
    new_resource.dbconfig_file = node['mongodb']['dbconfig_file']['mongod']
    new_resource.sysconfig_file = node['mongodb']['sysconfig_file']['mongod']
    new_resource.sysconfig_vars = node['mongodb']['sysconfig']['mongod']

    if new_resource.is_shard
      new_resource.config['sharding'] ||= {}
      new_resource.config['sharding']['clusterRole'] = 'shardsvr'
    end

    if node['mongodb']['config']['mongod']['storage']['dbPath'].nil?
      node.default['mongodb']['config']['mongod']['storage']['dbPath'] = '/data'
    end
    new_resource.dbpath = node['mongodb']['config']['mongod']['storage']['dbPath']
  end

  node.default['mongodb']['config']['configsvr'] = true if node['mongodb']['is_configserver']

  new_resource.name                       = params[:name]
  new_resource.logpath                    = params[:logpath]
  new_resource.replicaset                 = params[:replicaset]
  new_resource.service_action             = params[:action]
  new_resource.service_notifies           = params[:notifies]

  # TODO(jh): parameterize so we can make a resource provider
  new_resource.auto_configure_replicaset  = node['mongodb']['auto_configure']['replicaset']
  new_resource.auto_configure_sharding    = node['mongodb']['auto_configure']['sharding']
  new_resource.bind_ip                    = new_resource.config['net']['bindIp']
  new_resource.cluster_name               = node['mongodb']['cluster_name']
  new_resource.dbconfig_file_template     = node['mongodb']['dbconfig_file']['template']
  new_resource.init_dir                   = node['mongodb']['init_dir']
  new_resource.init_script_template       = node['mongodb']['init_script_template']
  new_resource.is_replicaset              = node['mongodb']['is_replicaset']
  new_resource.is_configserver            = node['mongodb']['is_configserver']
  new_resource.mongodb_group              = node['mongodb']['group']
  new_resource.mongodb_user               = node['mongodb']['user']
  new_resource.port                       = new_resource.config['net']['port']
  new_resource.root_group                 = node['mongodb']['root_group']
  new_resource.shard_name                 = node['mongodb']['shard_name']
  new_resource.sharded_collections        = node['mongodb']['sharded_collections']
  new_resource.sysconfig_file_template    = node['mongodb']['sysconfig_file']['template']
  new_resource.template_cookbook          = node['mongodb']['template_cookbook']
  new_resource.ulimit                     = node['mongodb']['ulimit']
  new_resource.reload_action              = node['mongodb']['reload_action']

  # Upstart or sysvinit
  if platform?('ubuntu') && node['platform_version'].to_f < 15.04
    new_resource.init_file = File.join(node['mongodb']['init_dir'], "#{new_resource.name}.conf")
    mode = '0644'
  else
    new_resource.init_file = File.join(node['mongodb']['init_dir'], new_resource.name)
    mode = '0755'
  end

  # TODO(jh): reimplement using polymorphism
  replicaset_name = if new_resource.is_replicaset
                      if new_resource.replicaset_name
                        # trust a predefined replicaset name
                        new_resource.replicaset_name
                      elsif new_resource.is_shard && new_resource.shard_name
                        # for replicated shards we autogenerate
                        # the replicaset name for each shard
                        "rs_#{new_resource.shard_name}"
                      else
                        # Well shoot, we don't have a predefined name and we aren't
                        # really sharded. If we want backwards compatibility, this should be:
                        #   replicaset_name = "rs_#{new_resource.shard_name}"
                        # which with default values defaults to:
                        #   replicaset_name = 'rs_default'
                        # But using a non-default shard name when we're creating a default
                        # replicaset name seems surprising to me and needlessly arbitrary.
                        # So let's use the *default* default in this case:
                        'rs_default'
                      end
                    end

  # default file
  template new_resource.sysconfig_file do
    cookbook new_resource.template_cookbook
    source new_resource.sysconfig_file_template
    group new_resource.root_group
    owner 'root'
    mode '0644'
    variables(
      sysconfig: new_resource.sysconfig_vars
    )
    notifies new_resource.reload_action, "service[#{new_resource.name}]"
  end

  # config file
  template new_resource.dbconfig_file do
    cookbook new_resource.template_cookbook
    source new_resource.dbconfig_file_template
    group new_resource.root_group
    owner 'root'
    variables(
      config: new_resource.config
    )
    helpers MongoDBConfigHelpers
    mode '0644'
    notifies new_resource.reload_action, "service[#{new_resource.name}]"
  end

  # log dir [make sure it exists]
  directory File.dirname(new_resource.logpath) do
    owner new_resource.mongodb_user
    group new_resource.mongodb_group
    mode '0755'
    action :create
    recursive true
    not_if { new_resource.logpath.nil? || new_resource.logpath.empty? }
  end

  # dbpath dir [make sure it exists] unless it is a mongos
  unless new_resource.is_mongos
    directory new_resource.dbpath do
      owner new_resource.mongodb_user
      group new_resource.mongodb_group
      mode '0755'
      action :create
      recursive true
    end
  end

  # Reload systemctl for RHEL 7+ after modifying the init file.
  execute "mongodb-systemctl-daemon-reload-#{new_resource.name}" do
    command 'systemctl daemon-reload'
    action :nothing
  end

  # init script
  template new_resource.init_file do
    cookbook new_resource.template_cookbook
    source new_resource.init_script_template
    group new_resource.root_group
    owner 'root'
    mode mode
    variables(
      provides: provider,
      dbconfig_file: new_resource.dbconfig_file,
      sysconfig_file: new_resource.sysconfig_file,
      ulimit: new_resource.ulimit,
      bind_ip: new_resource.bind_ip,
      port: new_resource.port
    )
    notifies new_resource.reload_action, "service[#{new_resource.name}]"

    if (platform_family?('rhel') && !platform?('amazon') && node['platform_version'].to_i >= 7) || (platform?('debian') && node['platform_version'].to_i >= 8)
      notifies :run, "execute[mongodb-systemctl-daemon-reload-#{new_resource.name}]", :immediately
    end
  end

  # service
  service new_resource.name do
    supports status: true, restart: true
    action new_resource.service_action
    new_resource.service_notifies.each do |service_notify|
      notifies :run, service_notify
    end
    notifies :run, 'ruby_block[config_replicaset]', :immediately if new_resource.is_replicaset && new_resource.auto_configure_replicaset
    notifies :run, 'ruby_block[config_sharding]', :immediately if new_resource.is_mongos && new_resource.auto_configure_sharding
    # we don't care about a running mongodb service in these cases, all we need is stopping it
    ignore_failure true if new_resource.name == 'mongodb'
  end

  # replicaset
  if new_resource.is_replicaset && new_resource.auto_configure_replicaset
    rs_nodes = search(
      :node,
      "mongodb_cluster_name:#{new_resource.cluster_name} AND " \
      'mongodb_is_replicaset:true AND ' \
      "mongodb_config_mongod_replication_replSetName:#{new_resource.replicaset_name} AND " \
      "chef_environment:#{node.chef_environment}"
    )

    ruby_block 'config_replicaset' do
      block do
        MongoDB.configure_replicaset(node, replicaset_name, rs_nodes) unless new_resource.replicaset.nil?
      end
      action :nothing
    end

    ruby_block 'run_config_replicaset' do
      block {}
      notifies :run, 'ruby_block[config_replicaset]'
    end
  end

  # sharding
  if new_resource.is_mongos && new_resource.auto_configure_sharding
    # add all shards
    # configure the sharded collections

    shard_nodes = search(
      :node,
      "mongodb_cluster_name:#{new_resource.cluster_name} AND " \
      "mongodb_shard_name:#{new_resource.shard_name} AND " \
      'mongodb_is_shard:true AND ' \
      "chef_environment:#{node.chef_environment}"
    )

    ruby_block 'config_sharding' do
      block do
        MongoDB.configure_shards(node, shard_nodes)
        MongoDB.configure_sharded_collections(node, new_resource.sharded_collections)
      end
      action :nothing
    end

    ruby_block 'run_config_sharding' do
      block {}
      notifies :run, 'ruby_block[config_sharding]'
    end
  end
end
