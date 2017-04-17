# Mongos service
describe service('mongos') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

# Mongos process
describe port(27017) do
  it { should be_listening }
  its('protocols') { should eq ['tcp'] }
end

# Config process
describe port(27019) do
  it { should be_listening }
  its('protocols') { should eq ['tcp'] }
end
