# Mongos service
describe service('mongos') do
  it { should be_installed }
  it { should be_running }
end

# SystemD on Debian 8 doesn't detect enabled sysvinit services correctly
unless os[:family] == 'debian' && os[:release] =~ /^8\./
  describe service('mongos') do
    it { should be_enabled }
  end
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
