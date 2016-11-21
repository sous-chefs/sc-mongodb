#
# Cookbook Name:: mongodb
# Recipe:: mms_backup_agent
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

Chef::Log.warn 'Found empty mms_agent.api_key attribute' if node['mongodb']['mms_agent']['api_key'].nil?

arch = node['kernel']['machine']
agent_type = 'backup'
package = format(node['mongodb']['mms_agent']['package_url'], agent_type: agent_type)
package_opts = ''

case node['platform_family']
when 'debian'
  arch = 'amd64' if arch == 'x86_64'
  package = "#{package}_#{node['mongodb']['mms_agent']['backup']['version']}_#{arch}.deb"
  provider = Chef::Provider::Package::Dpkg
  # Without this, if the package changes the config files that we rewrite install fails
  package_opts = '--force-confold'
when 'rhel'
  package = "#{package}-#{node['mongodb']['mms_agent']['backup']['version']}.#{arch}.rpm"
  provider = Chef::Provider::Package::Rpm
else
  Chef::Log.warn('Unsupported platform family for MMS Agent.')
  return
end

remote_file "#{Chef::Config[:file_cache_path]}/mongodb-mms-backup-agent" do
  source package
end

package 'mongodb-mms-backup-agent' do
  source "#{Chef::Config[:file_cache_path]}/mongodb-mms-backup-agent"
  provider provider
  options package_opts
end

template '/etc/mongodb-mms/backup-agent.config' do
  source 'mms_agent_config.erb'
  owner node['mongodb']['mms_agent']['user']
  group node['mongodb']['mms_agent']['group']
  mode 0600
  variables(
    config: node['mongodb']['mms_agent']['backup']
  )
  action :create
  notifies :restart, 'service[mongodb-mms-backup-agent]', :delayed
end

service 'mongodb-mms-backup-agent' do
  provider Chef::Provider::Service::Upstart if node['mongodb']['apt_repo'] == 'ubuntu-upstart'
  # restart is broken on rhel (MMS-1597)
  supports start: true, stop: true, restart: true, status: true
  action :nothing
end
