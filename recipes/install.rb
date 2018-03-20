#
# Cookbook Name:: mongodb
# Recipe:: install
#
# Copyright 2011, edelight GmbH
# Authors:
#       Markus Korn <markus.korn@edelight.de>
#
# Copyright 2016-2017, Grant Ridder
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

# TODO: still need all of the tools?
# yum_package[autoconf, bison, flex, gcc, gcc-c++, gettext, kernel-devel, make, m4, ncurses-devel, patch]
build_essential 'build-tools'

config_type = node['mongodb']['is_mongos'] ? 'mongos' : 'mongod'

config = node['mongodb']['config'][config_type]
dbconfig_file = node['mongodb']['dbconfig_file'][config_type]
sysconfig_file = node['mongodb']['sysconfig_file'][config_type]

# prevent-install defaults, but don't overwrite
file "#{sysconfig_file} install" do
  path sysconfig_file
  content 'ENABLE_MONGODB=no'
  group node['mongodb']['root_group']
  owner 'root'
  mode '0644'
  action :create_if_missing
end

# just-in-case config file drop
template "#{dbconfig_file} install" do
  path dbconfig_file
  cookbook node['mongodb']['template_cookbook']
  source node['mongodb']['dbconfig_file']['template']
  group node['mongodb']['root_group']
  owner 'root'
  mode '0644'
  variables(
    config: config
  )
  helpers MongoDBConfigHelpers
  action :create_if_missing
end

# and we install our own init file
if node['platform'] == 'ubuntu' && node['platform_version'].to_f < 15.04
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

template "#{init_file} install" do
  path init_file
  cookbook node['mongodb']['template_cookbook']
  source node['mongodb']['init_script_template']
  group node['mongodb']['root_group']
  owner 'root'
  mode mode
  variables(
    provides: 'mongod',
    dbconfig_file: dbconfig_file,
    sysconfig_file: sysconfig_file,
    ulimit: node['mongodb']['ulimit'],
    bind_ip: config['net']['bindIp'],
    port: config['net']['port']
  )
  action :create_if_missing

  if (platform_family?('rhel') && node['platform'] != 'amazon' && node['platform_version'].to_i >= 7) || (node['platform'] == 'debian' && node['platform_version'].to_i >= 8)
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

# Change needed so that updates work properly on debian based systems
if node['platform_family'] == 'debian'
  deb_pkgs = %w(
    server
    shell
    tools
    mongos
    ).map { |sfx| "#{node['mongodb']['package_name']}-#{sfx}" }

  package deb_pkgs do
    options node['mongodb']['packager_options']
    action :install
    version package_version
    not_if { node['mongodb']['install_method'] == 'none' }
  end
end

# Create keyFile if specified
key_file_content = node['mongodb']['key_file_content']

if key_file_content
  file config['security']['keyFile'] do
    owner node['mongodb']['user']
    group node['mongodb']['group']
    mode  '0600'
    backup false
    content key_file_content
  end
end

node.default['mongodb']['config'][config_type]['security']['keyFile'] = nil if key_file_content.nil?
