# frozen_string_literal: true

require 'spec_helper'

describe 'mongodb_agent' do
  step_into :mongodb_agent
  platform 'ubuntu', '24.04'

  recipe do
    mongodb_agent 'monitoring' do
      api_key 'abc123'
    end
  end

  it { is_expected.to create_remote_file(%r{/mongodb-mms-monitoring-agent_latest_amd64\.ubuntu1604\.deb$}) }
  it { is_expected.to install_package('mongodb-mms-monitoring-agent') }
  it { is_expected.to create_directory('/etc/mongodb-mms') }
  it { is_expected.to create_template('/etc/mongodb-mms/monitoring-agent.config') }
  it { is_expected.to enable_service('mongodb-mms-monitoring-agent') }
end
