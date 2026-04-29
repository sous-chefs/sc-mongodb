# frozen_string_literal: true

mongodb_ruby_gems 'mongo driver'

mongodb_user 'kitchen' do
  password 'blah123'
  roles ['readWrite']
  database 'admin'
  action :add
end
