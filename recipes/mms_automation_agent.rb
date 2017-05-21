#
# Cookbook Name:: mongodb
# Recipe:: mms_automation_agent
#
# Copyright 2017, Grant Ridder
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

Chef::Log.warn 'Found empty mms_agent.api_key attribute' if node['mongodb']['mms_agent']['api_key'].nil?

mongodb_agent 'automation' do
  config node['mongodb']['mms_agent']['automation']['config']
  group node['mongodb']['mms_agent']['automation']['group']
  package_url node['mongodb']['mms_agent']['automation']['package_url']
  user node['mongodb']['mms_agent']['automation']['user']
end
