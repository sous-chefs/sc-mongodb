# frozen_string_literal: true

provides :mongodb_config
unified_mode true

use '_partial/_instance'

property :data_path, [String, nil]
property :log_path, [String, nil]
property :key_file_content, [String, nil], sensitive: true
property :key_file_path, [String, nil]

default_action :create

action :create do
  directory ::File.dirname(effective_log_path) do
    owner effective_user
    group effective_group
    mode '0755'
    recursive true
    action :create
    not_if { effective_log_path.nil? || effective_log_path.empty? }
  end

  directory effective_data_path do
    owner effective_user
    group effective_group
    mode '0755'
    recursive true
    action :create
    not_if { new_resource.mongodb_type == 'mongos' || effective_data_path.nil? }
  end

  file effective_config_path do
    content lazy { ScMongoDB::Helpers::Config.to_yaml_options(effective_config) }
    owner 'root'
    group new_resource.root_group
    mode '0644'
    action :create
  end

  if new_resource.key_file_content && effective_key_file_path
    file effective_key_file_path do
      owner effective_user
      group effective_group
      mode '0600'
      backup false
      sensitive true
      content new_resource.key_file_content
      action :create
    end
  end
end

action :delete do
  file effective_config_path do
    action :delete
  end

  if effective_key_file_path
    file effective_key_file_path do
      action :delete
    end
  end

  directory effective_data_path do
    recursive true
    action :delete
    not_if { new_resource.mongodb_type == 'mongos' || effective_data_path.nil? }
  end
end

action_class do
  include ScMongoDB::Helpers::Defaults

  def effective_config
    config = mongodb_deep_merge(mongodb_default_config(service_binary, new_resource.port, new_resource.bind_ip), new_resource.config)
    config['storage'] ||= {}
    config['storage']['dbPath'] = effective_data_path if service_binary == 'mongod' && effective_data_path
    config['security'] ||= {}
    config['security']['keyFile'] = effective_key_file_path if new_resource.key_file_content || new_resource.key_file_path
    config
  end

  def service_binary
    new_resource.mongodb_type == 'mongos' ? 'mongos' : 'mongod'
  end

  def effective_config_path
    new_resource.config_path || (service_binary == 'mongos' ? '/etc/mongos.conf' : '/etc/mongod.conf')
  end

  def effective_data_path
    new_resource.data_path || new_resource.config.dig('storage', 'dbPath') || mongodb_db_path
  end

  def effective_log_path
    new_resource.log_path || new_resource.config.dig('systemLog', 'path') || (service_binary == 'mongos' ? '/var/log/mongodb/mongos.log' : '/var/log/mongodb/mongod.log')
  end

  def effective_key_file_path
    new_resource.key_file_path || new_resource.config.dig('security', 'keyFile')
  end

  def effective_user
    new_resource.user || mongodb_user
  end

  def effective_group
    new_resource.group || mongodb_group
  end
end
