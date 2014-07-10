# Set this to true in your chef json
# to require all users to authenticate
default['mongodb']['config']['auth'] = false

default['mongodb']['admin'] = {
  'username' => 'admin',
  'password' => '2NCDza6MLjDUm0m',
  'roles' => %w(userAdminAnyDatabase dbAdminAnyDatabase),
  'database' => 'admin'
}

default['mongodb']['users'] = []
