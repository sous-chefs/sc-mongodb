# frozen_string_literal: true

control 'sc-mongodb-configserver-01' do
  impact 1.0
  title 'Config server configuration is rendered'

  describe file('/etc/mongod.conf') do
    it { should exist }
    its('content') { should match(/clusterRole: configsvr/) }
    its('content') { should match(/port: 27019/) }
  end
end
