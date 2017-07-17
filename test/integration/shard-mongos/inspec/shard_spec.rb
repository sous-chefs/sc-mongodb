# mongod service is running
describe service('mongod') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

# only 1 shard initialized
describe bash('mongo --eval "sh.status()" | grep \'{  "_id"\' | grep host | wc -l') do
  its('exit_status') { should eq 0 }
  its(:stdout) { should match '1' }
end

# shard initialized with the correct node names
describe bash('mongo --eval "sh.status()"') do
  its('exit_status') { should eq 0 }

  # Sharding
  its(:stdout) { should match %r(.*^\s{2}shards:\n\t{  "_id" : "kitchen1",  "host" : "kitchen1/mongo1:27017,mongo2:27017,mongo3:27017" }$.*) }

  # Sharded collection
  its(:stdout) { should match(/.*^\t{  "_id" : "test",  "primary" : "kitchen1",  "partitioned" : true }\n\t{2}test.testing\n\t{3}shard key: { "_id" : 1 }$.*/) }
end
