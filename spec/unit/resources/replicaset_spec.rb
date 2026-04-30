# frozen_string_literal: true

require 'spec_helper'

describe 'mongodb_replicaset' do
  step_into :mongodb_replicaset
  platform 'ubuntu', '24.04'

  recipe do
    mongodb_replicaset 'rs_default' do
      auto_configure false
    end
  end

  it { is_expected.to install_mongodb_ruby_gems('replicaset gems') }
  it { is_expected.to create_mongodb_instance('mongod') }
  it { is_expected.not_to run_ruby_block('configure MongoDB replicaset rs_default') }
end
