# @test "requires authentication" {
#     mongosh --eval "db.stats().ok"
#     ! [ $? -eq 1 ]
# }
#
# @test "admin user created" {
#     mongosh admin -u admin -p admin --eval "db.stats().ok"
#     [ $? -eq 0 ]
# }

describe service('mongod') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

# admin user created
describe bash('mongosh admin -u admin -p admin --eval "db.stats().ok"') do
  its('exit_status') { should eq 0 }
end

describe bash('mongosh --eval "db.stats().ok"') do
  its('exit_status') { should_not eq 1 }
end

# kitchen read user created
describe bash(%(mongosh admin -u admin -p admin --eval "db.system.users.find({'_id' : 'admin.kitchen', 'user' : 'kitchen', 'db' : 'admin', 'roles' : [ { 'role' : 'read', 'db' : 'admin' } ]})" | grep _id)) do
  its('exit_status') { should eq 0 }
end
