# frozen_string_literal: true

%w(automation backup monitoring).each do |agent_type|
  control "sc-mongodb-agent-#{agent_type}-01" do
    impact 0.7
    title "MongoDB #{agent_type} agent configuration exists"

    describe file("/etc/mongodb-mms/#{agent_type}-agent.config") do
      it { should exist }
      its('mode') { should cmp '0600' }
    end
  end
end
