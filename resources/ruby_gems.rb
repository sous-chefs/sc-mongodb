# frozen_string_literal: true

provides :mongodb_ruby_gems
unified_mode true

property :gem_set, String, name_property: true
property :gems, Hash, default: { 'mongo' => '~> 2.0' }
property :install_build_packages, [true, false], default: true

default_action :install

action :install do
  package mongodb_gem_build_packages do
    action :install
    only_if { new_resource.install_build_packages }
  end

  package mongodb_sasl_dev_package do
    action :install
    only_if { new_resource.install_build_packages }
  end

  new_resource.gems.each do |gem_name, gem_version|
    chef_gem gem_name do
      version gem_version
      compile_time false
      action :install
    end
  end
end

action :remove do
  new_resource.gems.each_key do |gem_name|
    chef_gem gem_name do
      action :remove
    end
  end
end

action_class do
  include ScMongoDB::Helpers::Defaults
end
