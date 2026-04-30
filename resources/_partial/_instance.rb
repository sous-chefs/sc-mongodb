# frozen_string_literal: true

property :instance_name, String, name_property: true
property :mongodb_type, String, equal_to: %w(mongod mongos configserver), default: 'mongod'
property :version, [String, Float], default: '8.0'
property :package_version, [String, nil]
property :package_name, String, default: 'mongodb-org'
property :config, Hash, default: {}
property :port, Integer, default: 27_017
property :bind_ip, String, default: '0.0.0.0'
property :config_path, [String, nil]
property :user, [String, nil]
property :group, [String, nil]
property :root_group, String, default: 'root'
