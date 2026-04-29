# frozen_string_literal: true

require 'spec_helper'
require_relative '../libraries/helpers'

describe ScMongoDB::Helpers::Config do
  it 'renders compact YAML configuration' do
    config = {
      'net' => {
        'port' => 27_017,
        'bindIp' => '0.0.0.0',
      },
      'storage' => {
        'dbPath' => '/var/lib/mongodb',
        'empty' => nil,
      },
    }

    expect(described_class.to_yaml_options(config)).to include("port: 27017\n")
    expect(described_class.to_yaml_options(config)).not_to include('empty')
  end
end
