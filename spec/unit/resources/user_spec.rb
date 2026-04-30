# frozen_string_literal: true

require 'spec_helper'

describe 'mongodb_user' do
  platform 'ubuntu', '24.04'

  recipe do
    mongodb_user 'kitchen' do
      password 'secret'
      roles ['readWrite']
      database 'admin'
      action :nothing
    end
  end

  it 'declares the user resource' do
    resource = chef_run.find_resource(:mongodb_user, 'kitchen')

    expect(resource.action).to eq([:nothing])
    expect(resource.roles).to eq(['readWrite'])
    expect(resource.database).to eq('admin')
  end
end
