# frozen_string_literal: true

require 'spec_helper'

describe 'mongodb_config' do
  step_into :mongodb_config
  platform 'ubuntu', '24.04'

  recipe do
    mongodb_config 'mongod' do
      config(
        'net' => {
          'port' => 27_018,
        }
      )
    end
  end

  it { is_expected.to create_directory('/var/log/mongodb') }
  it { is_expected.to create_directory('/var/lib/mongodb') }
  it { is_expected.to create_file('/etc/mongod.conf') }
  it { is_expected.to render_file('/etc/mongod.conf').with_content(/port: 27018/) }
end
