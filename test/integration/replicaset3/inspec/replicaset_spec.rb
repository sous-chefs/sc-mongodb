# mongod service is running
describe service('mongod') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

# replicaset initialized with 3 nodes
describe bash('mongo --eval "rs.status()" | grep name | wc -l') do
  its('exit_status') { should eq 0 }
  its(:stdout) { should match '3' }
end

# replicaset initialized with the correct node names
describe bash('mongo --eval "rs.status()"') do
  its('exit_status') { should eq 0 }
  its(:stdout) { should match(/.*^connecting to: test\n\{\n\t{1}"set" : "kitchen"\,$.*/) }
  its(:stdout) { should match(/.*^\t{3}"_id" : 0\,\n\t{3}"name" : "mongo1:27017"\,$.*/) }
  its(:stdout) { should match(/.*^\t{3}"_id" : 1\,\n\t{3}"name" : "mongo2:27017"\,$.*/) }
  its(:stdout) { should match(/.*^\t{3}"_id" : 2\,\n\t{3}"name" : "mongo3:27017"\,$.*/) }
end
