#
# Cookbook Name:: mongodb
# Recipe:: mms_monitoring_agent
#
# Copyright 2011, edelight GmbH
# Authors:
#       Markus Korn <markus.korn@edelight.de>
#
# Copyright 2016-2017, Grant Ridder
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

# The MMS agent is hard coded for a specific version of libsasl that is newer
# on RHEL 7
# See http://stackoverflow.com/a/26242879
link '/usr/lib64/libsasl2.so.2 mms_monitoring_agent' do
  to '/usr/lib64/libsasl2.so.3'
  target_file '/usr/lib64/libsasl2.so.2'
  not_if { ::File.exist?('/usr/lib64/libsasl2.so.2') }
  only_if { ::File.exist?('/usr/lib64/libsasl2.so.3') }
  only_if { node['platform_family'] == 'rhel' && node['platform_version'].to_i == 7 }
end

mongodb_agent 'monitoring' do
  config node['mongodb']['mms_agent']['monitoring']['config']
  group node['mongodb']['mms_agent']['monitoring']['group']
  package_url node['mongodb']['mms_agent']['monitoring']['package_url']
  user node['mongodb']['mms_agent']['monitoring']['user']
end
