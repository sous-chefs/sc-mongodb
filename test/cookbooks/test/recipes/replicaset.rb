# frozen_string_literal: true

mongodb_replicaset 'rs_default' do
  auto_configure false
  action :create
end
