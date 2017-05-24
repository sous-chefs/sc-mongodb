#
# Cookbook Name:: sc-mongodb
# Recipe:: mongos
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

node.override['mongodb']['is_mongos'] = true

include_recipe 'sc-mongodb::install'

ruby_block 'chef_gem_at_converge_time' do
  block do
    node['mongodb']['ruby_gems'].each do |gem, version|
      version = Gem::Dependency.new(gem, version)
      Chef::Provider::Package::Rubygems::GemEnvironment.new.install(version)
    end
  end
end

configsrvs = search(
  :node,
  "mongodb_cluster_name:#{node['mongodb']['cluster_name']} AND \
   mongodb_is_configserver:true AND \
   chef_environment:#{node.chef_environment}"
)

if configsrvs.length != 1 && configsrvs.length != 3
  Chef::Log.error("Found #{configsrvs.length} configservers, need either one or three of them")
  raise 'Wrong number of configserver nodes' unless Chef::Config[:solo]
end

mongodb_instance node['mongodb']['instance_name']['mongos'] do
  mongodb_type 'mongos'
  configservers configsrvs
end
