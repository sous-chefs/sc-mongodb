#
# Cookbook Name:: sc-mongodb
# Recipe:: replicaset
#
# Copyright 2011, edelight GmbH
#
# Copyright 2016, Sous Chefs
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

node.set['mongodb']['is_replicaset'] = true
node.set['mongodb']['cluster_name'] = node['mongodb']['cluster_name']

include_recipe 'sc-mongodb::install'

ruby_block 'chef_gem_at_converge_time' do
  block do
    node['mongodb']['ruby_gems'].each do |gem, version|
      version = Gem::Dependency.new(gem, version)
      Chef::Provider::Package::Rubygems::GemEnvironment.new.install(version)
    end
  end
end

mongodb_instance node['mongodb']['instance_name'] do
  mongodb_type 'mongod'
  port         node['mongodb']['config']['port']
  logpath      node['mongodb']['config']['logpath']
  dbpath       node['mongodb']['config']['dbpath']
  replicaset   node
  enable_rest  node['mongodb']['config']['rest']
  smallfiles   node['mongodb']['config']['smallfiles']
  not_if { node['mongodb']['is_shard'] }
end
