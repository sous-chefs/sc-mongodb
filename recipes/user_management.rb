chef_gem 'mongo'

users = node[:mongodb][:users]

# Add each user specified in attributes
users.each do |user|
  mongodb_user user['username'] do
    password user['password']
    roles user['roles']
    database user['database']
    action :add
  end
end
