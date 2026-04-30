# frozen_string_literal: true

mongodb_sharding 'configserver' do
  role 'configserver'
  port 27_019
  config(
    'sharding' => {
      'clusterRole' => 'configsvr',
    }
  )
  action :create
end
