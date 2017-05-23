describe service('mongodb-mms-monitoring-agent') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

describe file('/etc/mongodb-mms/monitoring-agent.config') do
  its('content') { should match(/(mmsApiKey=randomkey)/) }
  its('content') { should match(%r{(mmsBaseUrl=https://mms.mongodb.com)}) }
end
