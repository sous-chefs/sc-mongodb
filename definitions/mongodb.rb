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

define :mongodb_instance,
    :mongodb_type => "mongod",
    :action => [:enable, :start],
    :logpath => "/var/log/mongodb",
    :dbpath => "/data",
    :configserver => [],
    :replicaset => nil,
    :notifies => [] do

  if !["mongod", "shard", "configserver", "mongos"].include?(params[:mongodb_type])
    raise ArgumentError, ":mongodb_type must be 'mongod', 'shard', 'configserver' or 'mongos'; was #{params[:mongodb_type].inspect}"
  end

  include_recipe "mongodb::default"

  name                       = params[:name]
  configserver_nodes         = params[:configserver]
  dbpath                     = params[:dbpath]
  logpath                    = params[:logpath]
  replicaset                 = params[:replicaset]
  service_action             = params[:action]
  service_notifies           = params[:notifies]
  type                       = params[:mongodb_type]

  # TODO(jh): parameterize so we can make a resource provider
  auto_configure_replicaset  = node['mongodb']['auto_configure']['replicaset']
  auto_configure_sharding    = node['mongodb']['auto_configure']['sharding']
  cluster_name               = node['mongodb']['cluster_name']
  dbconfig_file              = node['mongodb']['dbconfig_file']
  dbconfig_file_template     = node['mongodb']['dbconfig_file_template']
  init_dir                   = node['mongodb']['init_dir']
  init_script_template       = node['mongodb']['init_script_template']
  mongodb_group              = node['mongodb']['group']
  mongodb_user               = node['mongodb']['user']
  root_group                 = node['mongodb']['root_group']
  sharded_collections        = node['mongodb']['sharded_collections']
  sysconfig_file             = node['mongodb']['sysconfig_file']
  sysconfig_file_template    = node['mongodb']['sysconfig_file_template']
  sysconfig_vars             = node['mongodb']['sysconfig']
  template_cookbook          = node['mongodb']['template_cookbook']

  if node['mongodb']['apt_repo'] == "ubuntu-upstart" then
    init_file = File.join(node['mongodb']['init_dir'], "#{name}.conf")
  else
    init_file = File.join(node['mongodb']['init_dir'], "#{name}")
  end

  if type == "shard"
    if replicaset.nil?
      replicaset_name = nil
    else
      # for replicated shards we autogenerate the replicaset name for each shard
      replicaset_name = "rs_#{replicaset['mongodb']['shard_name']}"
    end
  else
    # if there is a predefined replicaset name we use it,
    # otherwise we try to generate one using 'rs_$SHARD_NAME'
    begin
      replicaset_name = replicaset['mongodb']['replicaset_name']
    rescue
      replicaset_name = nil
    end
    if replicaset_name.nil?
      begin
        replicaset_name = "rs_#{replicaset['mongodb']['shard_name']}"
      rescue
        replicaset_name = nil
      end
    end
  end

  if type != "mongos"
    provider = "mongod"
    configserver = nil
  else
    provider = "mongos"
    dbpath = nil
    configserver = configserver_nodes.collect{|n| "#{(n['mongodb']['configserver_url'] || n['fqdn'])}:#{n['mongodb']['port']}" }.sort.join(",")
  end

  # default file
  template sysconfig_file do
    action :create
    cookbook template_cookbook
    source sysconfig_file_template
    group root_group
    owner "root"
    mode "0644"
    variables(
      "sysconfig" => sysconfig_vars
    )
    notifies :restart, "service[#{name}]"
  end

  # config file
  template dbconfig_file do
    cookbook template_cookbook
    source dbconfig_file_template
    group root_group
    owner "root"
    mode "0644"
    action :create


  # log dir [make sure it exists]
  directory logpath do
    owner mongodb_user
    group mongodb_group
    mode "0755"
    action :create
    recursive true
  end

  if type != "mongos"
    # dbpath dir [make sure it exists]
    directory dbpath do
      owner mongodb_user
      group mongodb_group
      mode "0755"
      action :create
      recursive true
    end
  end

  # init script
  template init_file do
    cookbook template_cookbook
    source init_script_template
    group root_group
    owner "root"
    mode "0755"
    variables({
        :provides => provider
    })
    action :create
  end

  # service
  service name do
    supports :status => true, :restart => true
    action service_action
    service_notifies.each do |service_notify|
      notifies :run, service_notify
    end
    if !replicaset_name.nil? && auto_configure_replicaset
      notifies :create, "ruby_block[config_replicaset]"
    end
    if type == "mongos" && auto_configure_sharding
      notifies :create, "ruby_block[config_sharding]", :immediately
    end
    if name == "mongodb"
      # we don't care about a running mongodb service in these cases, all we need is stopping it
      ignore_failure true
    end
  end

  # replicaset
  if !replicaset_name.nil? && auto_configure_replicaset
    rs_nodes = search(
      :node,
      "mongodb_cluster_name:#{replicaset['mongodb']['cluster_name']} AND \
       recipes:mongodb\\:\\:replicaset AND \
       mongodb_shard_name:#{replicaset['mongodb']['shard_name']} AND \
       chef_environment:#{replicaset.chef_environment}"
    )

    ruby_block "config_replicaset" do
      block do
        if not replicaset.nil?
          MongoDB.configure_replicaset(replicaset, replicaset_name, rs_nodes)
        end
      end
      action :nothing
    end

    ruby_block "run_config_replicaset" do
      block {}
      notifies :create, "ruby_block[config_replicaset]"
    end
  end

  # sharding
  if type == "mongos" && auto_configure_sharding
    # add all shards
    # configure the sharded collections

    shard_nodes = search(
      :node,
      "mongodb_cluster_name:#{cluster_name} AND \
       recipes:mongodb\\:\\:shard AND \
       chef_environment:#{node.chef_environment}"
    )

    ruby_block "config_sharding" do
      block do
        if type == "mongos"
          MongoDB.configure_shards(node, shard_nodes)
          MongoDB.configure_sharded_collections(node, sharded_collections)
        end
      end
      action :nothing
    end
  end
end
