#
# Cookbook Name:: mongodb
# Resource:: instance
#
# Copyright 2011, edelight GmbH
# Authors:
#       Joseph Holsten <joseph@josephholsten.com>
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

class Chef
  class Resource::MongodbInstance < Resource
    include Poise
    actions(:enable, :start, :stop, :disable, :status, :restart)

    attribute(:logpath,            kind_of: String,              default: '/var/log/mongodb/mongodb.log')
    attribute(:dbpath,             kind_of: String,              default: '/data')
    attribute(:configserver_nodes, kind_of: Array,              default: [])
    attribute(:replicaset,         kind_of: [Array, NilClass],  default: nil)
    attribute(:service_action,     kind_of: Array,              default: [:enable, :start])
    attribute(:service_notifies,   kind_of: Array,              default: [])

    attribute(:is_configserver,  kind_of: String,  default: lazy { node['mongodb']['is_configserver'] })
    attribute(:is_mongos,        kind_of: String,  default: lazy { node['mongodb']['is_mongos'] })
    attribute(:is_replicaset,    kind_of: String,  default: lazy { node['mongodb']['is_replicaset'] })
    attribute(:is_shard,         kind_of: String,  default: lazy { node['mongodb']['is_shard'] })

    # This table is painfully wide, but it's really easiest to visually scan this way
    attribute(:auto_configure_replicaset,  kind_of: [TrueClass, FalseClass],  default: lazy { node['mongodb']['auto_configure']['replicaset'] })
    attribute(:auto_configure_sharding,    kind_of: [TrueClass, FalseClass],  default: lazy { node['mongodb']['auto_configure']['sharding'] })
    attribute(:bind_ip,                    kind_of: String,                   default: lazy { node['mongodb']['config']['bind_ip']})
    attribute(:cluster_name,               kind_of: String,                   default: lazy { node['mongodb']['cluster_name'] })
    attribute(:config,                     kind_of: String,                   default: lazy { node['mongodb']['config'] })
    attribute(:dbconfig_file,              kind_of: String,                   default: lazy { node['mongodb']['dbconfig_file'] })
    attribute(:dbconfig_file_template,     kind_of: String,                   default: lazy { node['mongodb']['dbconfig_file_template'] })
    attribute(:init_dir,                   kind_of: String,                   default: lazy { node['mongodb']['init_dir'] })
    attribute(:init_script_template,       kind_of: String,                   default: lazy { node['mongodb']['init_script_template'] })
    attribute(:mongodb_group,              kind_of: String,                   default: lazy { node['mongodb']['group'] })
    attribute(:mongodb_user,               kind_of: String,                   default: lazy { node['mongodb']['user'] })
    attribute(:port,                       kind_of: Integer,                  default: lazy { node['mongodb']['config']['port']})
    attribute(:reload_action,              kind_of: String,                   default: lazy { node['mongodb']['reload_action'] })
    attribute(:replicaset_name,            kind_of: String,                   default: lazy { node['mongodb']['config']['replSet'] })
    attribute(:root_group,                 kind_of: String,                   default: lazy { node['mongodb']['root_group'] })
    attribute(:shard_name,                 kind_of: String,                   default: lazy { node['mongodb']['shard_name'] })
    attribute(:sharded_collections,        kind_of: String,                   default: lazy { node['mongodb']['sharded_collections'] })
    attribute(:sysconfig_file,             kind_of: String,                   default: lazy { node['mongodb']['sysconfig_file'] })
    attribute(:sysconfig_file_template,    kind_of: String,                   default: lazy { node['mongodb']['sysconfig_file_template'] })
    attribute(:sysconfig_vars,             kind_of: Hash,                     default: lazy { node['mongodb']['sysconfig'] })
    attribute(:template_cookbook,          kind_of: String,                   default: lazy { node['mongodb']['template_cookbook'] })
    attribute(:ulimit,                     kind_of: String,                   default: lazy { node['mongodb']['ulimit'] })

    # XXX None of the config munging has been ported from the define impl

    def init_file
      if node['mongodb']['apt_repo'] == 'ubuntu-upstart'
        init_file = File.join(node['mongodb']['init_dir'], '#{name}.conf')
      else
        init_file = File.join(node['mongodb']['init_dir'], name)
      end
      return init_file
    end

    def init_file_mode
      if node['mongodb']['apt_repo'] == 'ubuntu-upstart'
        mode = '0644'
      else
        mode = '0755'
      end
      return mode
    end

    def provides
      if is_mongos
        'mongos'
      else
        'mongod'
      end
    end

    def configserver
      if is_mongos
        configserver_nodes.collect do |n|
          hostname = n['mongodb']['configserver_url'] || n['fqdn']
          port = n['mongodb']['port']
          "#{hostname}:#{port}"
        end.sort.join(",")
      end
    end

    def replicaset_name
      if is_replicaset
        if config['replSet']
          # trust a predefined replicaset name
          replicaset_name = config['replSet']
        elsif is_shard && shard_name
          # for replicated shards we autogenerate
          # the replicaset name for each shard
          replicaset_name = "rs_#{shard_name}"
        else
          # Well shoot, we don't have a predefined name and we aren't
          # really sharded. If we want backwards compatibility, this should be:
          #   replicaset_name = "rs_#{new_resource.shard_name}"
          # which with default values defaults to:
          #   replicaset_name = 'rs_default'
          # But using a non-default shard name when we're creating a default
          # replicaset name seems surprising to me and needlessly arbitrary.
          # So let's use the *default* default in this case:
          replicaset_name = 'rs_default'
        end
      else
        # not a replicaset, so no name
        replicaset_name = nil
      end

      return replicaset_name
    end

    def replicaset_nodes
      search(
        :node,
        "mongodb_cluster_name:#{new_resource.replicaset['mongodb']['cluster_name']} AND \
         mongodb_is_replicaset:true AND \
         mongodb_config_replSet:#{new_resource.replicaset['mongodb']['config']['replSet']} AND \
         chef_environment:#{new_resource.replicaset.chef_environment}"
      )
    end

    def shard_nodes
      search(
        :node,
        "mongodb_cluster_name:#{new_resource.cluster_name} AND \
         mongodb_shard_name:#{new_resource.shard_name} AND \
         mongodb_is_shard:true AND \
         chef_environment:#{node.chef_environment}"
      )
    end

    def provides
      "mongod"
    end

    def should_configure_sharding?
      is_mongos && auto_configure_sharding
    end

    def should_configure_replicaset?
      is_replicaset && auto_configure_replicaset
    end
  end

  class Provider::MongodbInstance < Provider
    include Poise::Provider

    def action_enable
      converge_by("enable mongodb instance #{new_resource.name}") do
        notifying_block do
          create_configs
          ensure_dbpath
          configure_replicaset
          configure_sharding

          enable_service
        end
      end
    end

    def action_start
      converge_by("enable mongodb instance #{new_resource.name}") do
        notifying_block do
          create_configs
          ensure_dbpath
          configure_replicaset
          configure_sharding

          start_service
        end
      end
    end

    def action_restart
      converge_by("enable mongodb instance #{new_resource.name}") do
        notifying_block do
          restart_service
        end
      end
    end

    def action_disable
      converge_by("enable mongodb instance #{new_resource.name}") do
        notifying_block do
          disable_service
        end
      end
    end

    def action_stop
      converge_by("enable mongodb instance #{new_resource.name}") do
        notifying_block do
          stop_service
        end
      end
    end

    private

    def create_configs
      # default file
      template new_resource.sysconfig_file do
        cookbook new_resource.template_cookbook
        source new_resource.sysconfig_file_template
        group new_resource.root_group
        owner 'root'
        mode '0644'
        variables(
          :sysconfig => new_resource.sysconfig_vars
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
          :config => new_resource.config
        )
        helpers MongoDBConfigHelpers
        mode '0644'
        notifies new_resource.reload_action, "service[#{new_resource.name}]"
      end

      # Reload systemctl for RHEL 7+ after modifying the init file.
      execute 'mongodb-systemctl-daemon-reload' do
        command 'systemctl daemon-reload'
        action :nothing
      end

      # init script
      template new_resource.init_file do
        cookbook new_resource.template_cookbook
        source new_resource.init_script_template
        group new_resource.root_group
        owner 'root'
        mode new_resource.init_file_mode
        variables(
          :provides =>       new_resource.provides,
          :dbconfig_file  => new_resource.dbconfig_file,
          :sysconfig_file => new_resource.sysconfig_file,
          :ulimit =>         new_resource.ulimit,
          :bind_ip =>        new_resource.bind_ip,
          :port =>           new_resource.port
        )
        notifies new_resource.reload_action, "service[#{new_resource.name}]"

        if(platform_family?('rhel') && node['platform'] != 'amazon' && node['platform_version'].to_i >= 7)
          notifies :run, 'execute[mongodb-systemctl-daemon-reload]', :immediately
        end
      end

      # log dir [make sure it exists]
      if new_resource.logpath
        directory File.dirname(new_resource.logpath) do
          owner new_resource.mongodb_user
          group new_resource.mongodb_group
          mode '0755'
          action :create
          recursive true
        end
      end
    end

    def configure_replicaset
      @configure_replicaset ||= ruby_block "config_replicaset" do
        block do
          MongoDB.configure_replicaset(new_resource.replicaset, new_resource.replicaset_name, new_resource.replicaset_nodes) if new_resource.is_replicaset
        end
        only_if { new_resource.should_configure_replicaset? }
        action :nothing
      end
    end


    def configure_sharding
      @configure_sharding ||= ruby_block "config_sharding" do
        block do
          MongoDB.configure_shards(node, new_resource.shard_nodes)
          MongoDB.configure_sharded_collections(node, new_resource.sharded_collections)
        end
        only_if { new_resource.should_configure_sharding? }
        action :nothing
      end
    end

    def ensure_dbpath
      # dbpath dir [make sure it exists]
      directory new_resource.dbpath do
        owner new_resource.mongodb_user
        group new_resource.mongodb_group
        mode '0755'
        not_if { new_resource.is_mongos }
        action :create
        recursive true
      end
    end

    def enable_service
      service new_resource.name do
        provider Chef::Provider::Service::Upstart if node['mongodb']['apt_repo'] == 'ubuntu-upstart'
        supports :status => true, :restart => true
        action :enable

        new_resource.service_notifies.each do |service_notify|
          notifies :run, service_notify
        end
        notifies :create, config_replicaset, :immediately if new_resource.should_configure_replicaset?
        notifies :create, configure_sharding, :immediately if new_resource.should_configure_sharding?

        # we don't care about a running mongodb service in these cases, all we need is stopping it
        ignore_failure true if new_resource.name == 'mongodb'
      end
    end

    def start_service
      s = enable_service
      s.action :start
      s
    end

    def restart_service
      s = enable_service
      s.action :restart
      s
    end

    def status_service
      s = enable_service
      s.action :status
      s
    end

    def disable_service
      s = enable_service
      s.action :disable
      s
    end

    def stop_service
      s = enable_service
      s.action :stop
      s
    end
  end
end
