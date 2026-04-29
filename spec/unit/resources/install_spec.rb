# frozen_string_literal: true

require 'spec_helper'

describe 'mongodb_install' do
  step_into :mongodb_install
  platform 'ubuntu', '24.04'

  recipe do
    mongodb_install 'default' do
      version '8.0'
    end
  end

  it { is_expected.to create_mongodb_repository('mongodb') }
  it { is_expected.to install_package('mongodb-org') }
  it { is_expected.to install_package('mongodb-org-server') }
  it { is_expected.to install_package('mongodb-org-shell') }
  it { is_expected.to install_package('mongodb-org-tools') }
  it { is_expected.to install_package('mongodb-org-mongos') }
end
