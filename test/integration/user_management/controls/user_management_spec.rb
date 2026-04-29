# frozen_string_literal: true

control 'sc-mongodb-user-management-01' do
  impact 0.7
  title 'MongoDB Ruby driver is installed for user management'

  describe command('/opt/chef/embedded/bin/gem list mongo -i') do
    its('exit_status') { should eq 0 }
  end
end
