# mongodb | mongod
describe service('mongod') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

# replicaset initialized
describe bash('mongo --eval "db.stats().ok"') do
  its('exit_status') { should eq 0 }
end
