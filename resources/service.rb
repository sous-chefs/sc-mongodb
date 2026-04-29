# frozen_string_literal: true

provides :mongodb_service
unified_mode true

property :service_name, String, name_property: true
property :mongodb_type, String, equal_to: %w(mongod mongos), default: 'mongod'
property :config_path, [String, nil]
property :user, [String, nil]
property :group, [String, nil]
property :unit_after, Array, default: ['network-online.target']
property :unit_wants, Array, default: ['network-online.target']
property :limit_nofile, [Integer, String], default: 64_000
property :limit_nproc, [Integer, String], default: 32_000
property :service_actions, Array, default: [:enable, :start]

default_action :create

action :create do
  systemd_unit "#{new_resource.service_name}.service" do
    content(
      Unit: {
        Description: "MongoDB #{new_resource.service_name} instance",
        After: new_resource.unit_after.join(' '),
        Wants: new_resource.unit_wants.join(' '),
      },
      Service: {
        User: effective_user,
        Group: effective_group,
        ExecStart: "/usr/bin/#{new_resource.mongodb_type} --config #{effective_config_path}",
        Restart: 'on-failure',
        LimitNOFILE: new_resource.limit_nofile,
        LimitNPROC: new_resource.limit_nproc,
      },
      Install: {
        WantedBy: 'multi-user.target',
      }
    )
    action [:create]
    notifies :restart, "systemd_unit[#{new_resource.service_name}.service]", :delayed if new_resource.service_actions.include?(:start)
  end

  systemd_unit "#{new_resource.service_name}.service" do
    action new_resource.service_actions
  end
end

action :delete do
  systemd_unit "#{new_resource.service_name}.service" do
    action [:stop, :disable, :delete]
  end
end

action :start do
  systemd_unit "#{new_resource.service_name}.service" do
    action :start
  end
end

action :stop do
  systemd_unit "#{new_resource.service_name}.service" do
    action :stop
  end
end

action :restart do
  systemd_unit "#{new_resource.service_name}.service" do
    action :restart
  end
end

action_class do
  include ScMongoDB::Helpers::Defaults

  def effective_user
    new_resource.user || mongodb_user
  end

  def effective_group
    new_resource.group || mongodb_group
  end

  def effective_config_path
    new_resource.config_path || (new_resource.mongodb_type == 'mongos' ? '/etc/mongos.conf' : '/etc/mongod.conf')
  end
end
