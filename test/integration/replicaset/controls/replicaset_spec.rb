# frozen_string_literal: true

control 'sc-mongodb-replicaset-01' do
  impact 1.0
  title 'Replicaset configuration is rendered'

  describe file('/etc/mongod.conf') do
    it { should exist }
    its('content') { should match(/replSetName: rs_default/) }
  end
end
