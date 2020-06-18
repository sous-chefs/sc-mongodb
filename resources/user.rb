property :username, String, name_property: true
property :password, String
property :roles, Array
property :database, String
property :connection, Hash

action :add do
  require 'mongo'
  if defined?(Mongo::VERSION) && Gem::Version.new(Mongo::VERSION) >= Gem::Version.new('2.0.0')
    # The gem displays a lot of debug messages by default so set to INFO
    Mongo::Logger.logger.level = ::Logger::INFO
    add_user_v2(new_resource.username, new_resource.password, new_resource.database, new_resource.roles)
  else # mongo gem version 1.x
    add_user(new_resource.username, new_resource.password, new_resource.database, new_resource.roles)
  end
end

action :delete do
  require 'mongo'
  if defined?(Mongo::VERSION) && Gem::Version.new(Mongo::VERSION) >= Gem::Version.new('2.0.0')
    # The gem displays a lot of debug messages by default so set to INFO
    Mongo::Logger.logger.level = ::Logger::INFO
    delete_user_v2(new_resource.username, new_resource.database)
  else # mongo gem version 1.x
    delete_user(new_resource.username, new_resource.database)
  end
end

action :modify do
  require 'mongo'
  if defined?(Mongo::VERSION) && Gem::Version.new(Mongo::VERSION) >= Gem::Version.new('2.0.0')
    # The gem displays a lot of debug messages by default so set to INFO
    Mongo::Logger.logger.level = ::Logger::INFO
    # TODO: implement modify for 2.x gem
  else # mongo gem version 1.x
    add_user(new_resource.username, new_resource.password, new_resource.database, new_resource.roles)
  end
end

action_class do
  include MongoDB::Helpers::User
end
