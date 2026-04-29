# frozen_string_literal: true

require 'spec_helper'

describe 'mongodb_sharding' do
  step_into :mongodb_sharding
  platform 'ubuntu', '24.04'

  context 'configserver role' do
    recipe do
      mongodb_sharding 'configserver' do
        role 'configserver'
      end
    end

    it { is_expected.to create_mongodb_instance('mongod') }
  end

  context 'mongos role' do
    recipe do
      mongodb_sharding 'mongos' do
        role 'mongos'
        auto_configure false
      end
    end

    it { is_expected.to install_mongodb_ruby_gems('sharding gems') }
    it { is_expected.to create_mongodb_instance('mongos') }
  end
end
