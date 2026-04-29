# frozen_string_literal: true

require 'spec_helper'

describe 'mongodb_instance' do
  step_into :mongodb_instance
  platform 'ubuntu', '24.04'

  recipe do
    mongodb_instance 'mongod' do
      version '8.0'
    end
  end

  it { is_expected.to install_mongodb_install('mongod') }
  it { is_expected.to create_mongodb_config('mongod') }
  it { is_expected.to create_mongodb_service('mongod') }
end
