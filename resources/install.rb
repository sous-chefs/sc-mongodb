# frozen_string_literal: true

provides :mongodb_install
unified_mode true

property :install_name, String, name_property: true
property :install_method, String, equal_to: %w(mongodb-org none), default: 'mongodb-org'
property :repository_name, String, default: 'mongodb'
property :version, [String, Float], default: '8.0'
property :package_name, String, default: 'mongodb-org'
property :package_version, [String, nil]
property :package_options, [String, nil]
property :install_debian_components, [true, false], default: true

default_action :install

action :install do
  mongodb_repository new_resource.repository_name do
    version new_resource.version
    action :create
    only_if { new_resource.install_method == 'mongodb-org' }
  end

  package new_resource.package_name do
    options install_package_options
    version new_resource.package_version
    action :install
    not_if { new_resource.install_method == 'none' }
  end

  %w(server shell tools mongos).each do |suffix|
    package "#{new_resource.package_name}-#{suffix}" do
      options install_package_options
      version new_resource.package_version
      action :install
      only_if { platform_family?('debian') && new_resource.install_debian_components && new_resource.install_method != 'none' }
    end
  end
end

action :remove do
  %w(mongos tools shell server).each do |suffix|
    package "#{new_resource.package_name}-#{suffix}" do
      action :remove
      only_if { platform_family?('debian') && new_resource.install_debian_components }
    end
  end

  package new_resource.package_name do
    action :remove
  end

  mongodb_repository new_resource.repository_name do
    action :remove
  end
end

action_class do
  include ScMongoDB::Helpers::Defaults

  def install_package_options
    new_resource.package_options || mongodb_package_options
  end
end
