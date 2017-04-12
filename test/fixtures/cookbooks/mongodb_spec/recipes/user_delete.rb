mongodb_user '"kitchen" user delete' do
  username 'kitchen'
  database 'admin'
  connection node['mongodb']
  action :delete
end
