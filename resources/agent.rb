# frozen_string_literal: true

provides :mongodb_agent
unified_mode true

property :type, String, name_property: true, equal_to: %w(automation backup monitoring)
property :api_key, [String, nil], sensitive: true
property :config, Hash, default: {}
property :group, [String, nil]
property :package_url, [String, nil]
property :user, [String, nil]

default_action :create

action :create do
  Chef::Log.warn 'Found empty MongoDB agent api_key property' if new_resource.api_key.nil?

  filename = agent_package_url.split('/').last
  full_file_path = ::File.join(Chef::Config[:file_cache_path], filename)

  remote_file full_file_path do
    source agent_package_url
  end

  package "mongodb-mms-#{new_resource.type}-agent" do
    source full_file_path
    action :install
  end

  directory '/etc/mongodb-mms' do
    owner 'root'
    group 'root'
    mode '0755'
  end

  template "/etc/mongodb-mms/#{new_resource.type}-agent.config" do
    source 'mms_agent_config.erb'
    owner agent_user
    group agent_group
    mode '0600'
    sensitive true
    variables(config: agent_config)
    notifies :restart, "service[mongodb-mms-#{new_resource.type}-agent]", :delayed
  end

  service "mongodb-mms-#{new_resource.type}-agent" do
    supports start: true, stop: true, restart: true, status: true
    action [:enable, :start]
  end
end

action :delete do
  service "mongodb-mms-#{new_resource.type}-agent" do
    action [:disable, :stop]
  end

  package "mongodb-mms-#{new_resource.type}-agent" do
    action :remove
  end

  file "/etc/mongodb-mms/#{new_resource.type}-agent.config" do
    action :delete
  end

  file ::File.join(Chef::Config[:file_cache_path], agent_package_url.split('/').last) do
    action :delete
  end
end

action_class do
  include ScMongoDB::Helpers::Defaults

  def agent_user
    new_resource.user || (new_resource.type == 'automation' ? mongodb_user : 'mongodb-mms-agent')
  end

  def agent_group
    new_resource.group || agent_user
  end

  def agent_package_url
    new_resource.package_url || mongodb_agent_package_url(new_resource.type)
  end

  def agent_config
    mongodb_agent_config(new_resource.type, new_resource.api_key).merge(new_resource.config)
  end
end
