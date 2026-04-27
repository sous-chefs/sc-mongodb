# frozen_string_literal: true

provides :mongodb_repository
unified_mode true

property :repository_name, String, name_property: true
property :version, [String, Float], default: '8.0'

default_action :create

action :create do
  case node['platform_family']
  when 'debian'
    apt_repository new_resource.repository_name do
      uri mongodb_apt_uri
      distribution "#{node['lsb']['codename']}/mongodb-org/#{mongodb_major_version}"
      components platform?('ubuntu') ? ['multiverse'] : ['main']
      key "https://pgp.mongodb.com/server-#{mongodb_major_version}.asc"
    end
  when 'amazon', 'fedora', 'rhel'
    yum_repository new_resource.repository_name do
      description 'MongoDB RPM Repository'
      baseurl mongodb_yum_uri
      gpgkey "https://pgp.mongodb.com/server-#{mongodb_major_version}.asc"
      gpgcheck true
      sslverify true
      enabled true
    end
  else
    Chef::Log.warn("Adding the #{node['platform_family']} mongodb-org repository is not supported by this cookbook")
  end
end

action_class do
  def mongodb_major_version
    new_resource.version.to_f.to_s
  end

  def mongodb_apt_uri
    platform?('ubuntu') ? 'https://repo.mongodb.org/apt/ubuntu' : 'https://repo.mongodb.org/apt/debian'
  end

  def mongodb_yum_uri
    case node['platform']
    when 'amazon'
      "https://repo.mongodb.org/yum/amazon/2023/mongodb-org/#{mongodb_major_version}/$basearch/"
    when 'redhat', 'oracle', 'centos', 'rocky', 'almalinux'
      "https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/#{mongodb_major_version}/$basearch/"
    when 'fedora'
      "https://repo.mongodb.org/yum/redhat/9/mongodb-org/#{mongodb_major_version}/$basearch/"
    end
  end
end
