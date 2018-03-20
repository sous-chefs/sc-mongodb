#
# Cookbook Name:: sc-mongodb
# Resource:: agent
#
# Copyright 2017, Grant Ridder
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

provides :mongodb_agent

property :type, String, name_property: true, equal_to: %w(automation backup monitoring)

property :config, Hash
property :group, String
property :package_url, String
property :user, String

load_current_value do
  # TODO
end

action :create do
  filename = new_resource.package_url.split('/').last
  full_file_path = "#{Chef::Config[:file_cache_path]}/#{filename}"

  remote_file full_file_path do
    source new_resource.package_url
  end

  if filename.split('.').last == 'deb'
    dpkg_package "mongodb-mms-#{new_resource.type}-agent" do
      source full_file_path
    end
  else
    package "mongodb-mms-#{new_resource.type}-agent" do
      source full_file_path
    end
  end

  template "/etc/mongodb-mms/#{new_resource.type}-agent.config" do
    source 'mms_agent_config.erb'
    owner new_resource.user
    group new_resource.group
    mode 0600
    variables(
      config: new_resource.config
    )
    action :create
    notifies :restart, "service[mongodb-mms-#{new_resource.type}-agent]", :delayed
  end

  service "mongodb-mms-#{new_resource.type}-agent" do
    supports start: true, stop: true, restart: true, status: true
    action [:enable, :start]
  end
end

action :delete do
  filename = new_resource.package_url.split('/').last
  full_file_path = "#{Chef::Config[:file_cache_path]}/#{filename}"

  file full_file_path do
    action :delete
  end

  service "mongodb-mms-#{new_resource.type}-agent" do
    action [:disable, :stop]
  end

  package "mongodb-mms-#{new_resource.type}-agent" do
    action :remove
  end

  file "/etc/mongodb-mms/#{new_resource.type}-agent.config" do
    action :delete
  end
end
