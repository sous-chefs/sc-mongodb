# frozen_string_literal: true

require 'spec_helper'

describe 'mongodb_service' do
  step_into :mongodb_service
  platform 'ubuntu', '24.04'

  recipe do
    mongodb_service 'mongod'
  end

  it { is_expected.to create_systemd_unit('mongod.service') }
  it { is_expected.to enable_systemd_unit('mongod.service') }
  it { is_expected.to start_systemd_unit('mongod.service') }
end
