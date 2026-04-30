# frozen_string_literal: true

control 'sc-mongodb-mongos-01' do
  impact 1.0
  title 'Mongos configuration is rendered'

  describe file('/etc/mongos.conf') do
    it { should exist }
    its('content') { should match(/configDB: localhost:27019/) }
  end
end
