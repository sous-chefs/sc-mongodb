describe service('mongodb-mms-backup-agent') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

describe file('/etc/mongodb-mms/backup-agent.config') do
  its('content') { should match(/(mmsApiKey=randomkey)/) }
  its('content') { should match(/(mothership=api-backup.mongodb.com)/) }
end
