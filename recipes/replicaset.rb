#
# Cookbook:: sc-mongodb
# Recipe:: replicaset
#
# Copyright:: 2011, edelight GmbH
#
# Copyright:: 2016-2017, Grant Ridder
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

node.default['mongodb']['is_replicaset'] = true
node.default['mongodb']['cluster_name'] = node['mongodb']['cluster_name']

include_recipe 'sc-mongodb::install'
include_recipe 'sc-mongodb::mongo_gem'

mongodb_instance node['mongodb']['instance_name']['mongod'] do
  mongodb_type 'mongod'
  replicaset true
  not_if { node['mongodb']['is_shard'] }
end
