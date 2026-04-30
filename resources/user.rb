# frozen_string_literal: true

provides :mongodb_user
unified_mode true

property :username, String, name_property: true
property :password, String, sensitive: true
property :roles, Array, default: []
property :database, String, default: 'admin'
property :connection, Hash, default: {
  'host' => 'localhost',
  'port' => 27_017,
  'authentication' => {},
  'user_management' => {
    'connection' => {
      'retries' => 2,
      'delay' => 2,
    },
  },
}

default_action :add

action :add do
  require 'mongo'

  Mongo::Logger.logger.level = ::Logger::INFO if defined?(Mongo::Logger)
  add_user_v2(new_resource.username, new_resource.password, new_resource.database, new_resource.roles)
end

action :delete do
  require 'mongo'

  Mongo::Logger.logger.level = ::Logger::INFO if defined?(Mongo::Logger)
  delete_user_v2(new_resource.username, new_resource.database)
end

action :modify do
  action_add
end

action_class do
  include ScMongoDB::Helpers::User
end
