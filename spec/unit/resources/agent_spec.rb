# frozen_string_literal: true

require 'spec_helper'

describe 'mongodb_agent' do
  step_into :mongodb_agent

  context 'on Ubuntu 24.04' do
    platform 'ubuntu', '24.04'

    recipe do
      mongodb_agent 'monitoring' do
        api_key 'abc123'
      end
    end

    it { is_expected.to create_remote_file(%r{/mongodb-mms-monitoring-agent_latest_amd64\.ubuntu1604\.deb$}) }
    it { is_expected.to install_package('logrotate') }
    it { is_expected.to install_dpkg_package('mongodb-mms-monitoring-agent') }
    it { is_expected.to create_directory('/etc/mongodb-mms') }
    it { is_expected.to create_template('/etc/mongodb-mms/monitoring-agent.config') }
    it { is_expected.to enable_service('mongodb-mms-monitoring-agent') }
  end

  context 'on Amazon Linux 2023' do
    platform 'amazon', '2023'

    recipe do
      mongodb_agent 'backup' do
        api_key 'abc123'
        service_actions [:enable]
      end
    end

    it { is_expected.to create_remote_file(%r{/mongodb-mms-backup-agent-latest\.x86_64\.rpm$}) }
    it { is_expected.to install_rpm_package('mongodb-mms-backup-agent') }
    it { is_expected.to create_directory('/var/log/mongodb-mms') }
    it { is_expected.to create_systemd_unit('mongodb-mms-backup-agent.service') }
    it { is_expected.to delete_file('/etc/init.d/mongodb-mms-backup-agent') }
    it { is_expected.to enable_systemd_unit('mongodb-mms-backup-agent.service') }
    it { is_expected.not_to enable_service('mongodb-mms-backup-agent') }
  end
end
