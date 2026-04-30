# frozen_string_literal: true

mongodb_instance 'mongod' do
  version '8.0'
  action :create
end
