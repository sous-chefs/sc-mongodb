#
# Cookbook Name:: mongodb
# Recipe:: install
#
# Copyright 2011, edelight GmbH
# Authors:
#       Markus Korn <markus.korn@edelight.de>
#
# Copyright 2016, Sous Chefs
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

# install the mongodb org repo if necessary
include_recipe 'sc-mongodb::mongodb_org_repo' if node['mongodb']['install_method'] == 'mongodb-org'

build_essential 'build-tools'

# prevent-install defaults, but don't overwrite
file node['mongodb']['sysconfig_file'] do
  content 'ENABLE_MONGODB=no'
  group node['mongodb']['root_group']
  owner 'root'
  mode 0644
  action :create_if_missing
end

# just-in-case config file drop
template node['mongodb']['dbconfig_file'] do
  cookbook node['mongodb']['template_cookbook']
  source node['mongodb']['dbconfig_file_template']
  group node['mongodb']['root_group']
  owner 'root'
  mode 0644
  variables(
    config: node['mongodb']['config']
  )
  helpers MongoDBConfigHelpers
  action :create_if_missing
end

# and we install our own init file
if node['mongodb']['apt_repo'] == 'ubuntu-upstart'
  init_file = File.join(node['mongodb']['init_dir'], "#{node['mongodb']['default_init_name']}.conf")
  mode = '0644'
else
  init_file = File.join(node['mongodb']['init_dir'], node['mongodb']['default_init_name'])
  mode = '0755'
end

# Reload systemctl for RHEL 7+ after modifying the init file.
execute 'mongodb-systemctl-daemon-reload' do
  command 'systemctl daemon-reload'
  action :nothing
end

template init_file do
  cookbook node['mongodb']['template_cookbook']
  source node['mongodb']['init_script_template']
  group node['mongodb']['root_group']
  owner 'root'
  mode mode
  variables(
    provides: 'mongod',
    dbconfig_file: node['mongodb']['dbconfig_file'],
    sysconfig_file: node['mongodb']['sysconfig_file'],
    ulimit: node['mongodb']['ulimit'],
    bind_ip: node['mongodb']['config']['net']['bindIp'],
    port: node['mongodb']['config']['net']['port'],
    user: node['mongodb']['user']
  )
  action :create_if_missing

  if platform_family?('rhel') && node['platform'] != 'amazon' && node['platform_version'].to_i >= 7
    notifies :run, 'execute[mongodb-systemctl-daemon-reload]', :immediately
  end
end

# Adjust the version number for RHEL style if needed
package_version = case node['platform_family']
                  when 'rhel'
                    if node['platform'] == 'amazon'
                      "#{node['mongodb']['package_version']}-1.amzn1"
                    else
                      "#{node['mongodb']['package_version']}-1.el#{node['platform_version'].to_i}"
                    end
                  when 'fedora'
                    "#{node['mongodb']['package_version']}-1.el7"
                  else
                    node['mongodb']['package_version']
                  end

# Install
package node['mongodb']['package_name'] do
  options node['mongodb']['packager_options']
  action :install
  version package_version
  not_if { node['mongodb']['install_method'] == 'none' }
end

# Create keyFile if specified
if node['mongodb']['key_file_content']
  file node['mongodb']['config']['keyFile'] do
    owner node['mongodb']['user']
    group node['mongodb']['group']
    mode  '0600'
    backup false
    content node['mongodb']['key_file_content']
  end
end

node.default['mongodb']['config']['security']['keyFile'] = nil if node['mongodb']['key_file_content'].nil?
