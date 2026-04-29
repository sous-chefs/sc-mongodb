# frozen_string_literal: true

control 'sc-mongodb-default-01' do
  impact 1.0
  title 'MongoDB service and configuration are present'

  describe file('/etc/mongod.conf') do
    it { should exist }
    its('content') { should match(/bindIp: 0\.0\.0\.0/) }
    its('content') { should match(%r{dbPath: "?/var/lib/(mongo|mongodb)"?}) }
  end

  describe systemd_service('mongod') do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end
end
