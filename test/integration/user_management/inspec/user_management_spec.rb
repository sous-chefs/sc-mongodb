# @test "requires authentication" {
#     mongo --eval "db.stats().ok"
#     ! [ $? -eq 1 ]
# }
#
# @test "admin user created" {
#     mongo admin -u admin -p admin --eval "db.stats().ok"
#     [ $? -eq 0 ]
# }

describe service('mongodb') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

# admin user created
describe bash('mongo admin -u admin -p admin --eval "db.stats().ok"') do
  its('exit_status') { should eq 0 }
end

describe bash('mongo --eval "db.stats().ok"') do
  its('exit_status') { should_not eq 1 }
end
