# frozen_string_literal: true

mongodb_sharding 'mongos' do
  role 'mongos'
  config(
    'sharding' => {
      'configDB' => 'localhost:27019',
    }
  )
  auto_configure false
  action :create
end
