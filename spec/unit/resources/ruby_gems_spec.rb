# frozen_string_literal: true

require 'spec_helper'

describe 'mongodb_ruby_gems' do
  step_into :mongodb_ruby_gems
  platform 'ubuntu', '24.04'

  recipe do
    mongodb_ruby_gems 'driver' do
      gems('mongo' => '~> 2.0')
    end
  end

  it { is_expected.to install_package('build-essential') }
  it { is_expected.to install_package('libsasl2-dev') }
  it { is_expected.to install_chef_gem('mongo').with(version: '~> 2.0') }
end
