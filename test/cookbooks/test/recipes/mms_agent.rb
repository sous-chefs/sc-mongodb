# frozen_string_literal: true

%w(automation backup monitoring).each do |agent_type|
  mongodb_agent agent_type do
    api_key 'test-api-key'
    service_actions [:enable]
    action :create
  end
end
