describe service('mongodb-mms-automation-agent') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

describe file('/etc/mongodb-mms/automation-agent.config') do
  its('content') { should match(/(mmsApiKey=randomkey)/) }
  its('content') { should match(%r{(logFile=/var/log/mongodb-mms-automation/automation-agent.log)}) }
  its('content') { should match(%r{(mmsConfigBackup=/var/lib/mongodb-mms-automation/mms-cluster-config-backup.json)}) }
end
