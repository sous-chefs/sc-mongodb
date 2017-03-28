#
# Cookbook Name:: sc-mongodb
# Recipe:: default
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

include_recipe 'sc-mongodb::install'

# allow mongodb_instance to run if recipe isn't included
allow_mongodb_instance_run = true
conflicting_recipes = %w(sc-mongodb::replicaset sc-mongodb::shard sc-mongodb::configserver sc-mongodb::mongos sc-mongodb::mms_agent)
conflicting_recipes.each do |recipe|
  allow_mongodb_instance_run &&= false if node.run_context.loaded_recipe?(recipe)
end

mongodb_instance node['mongodb']['instance_name']['mongod'] do
  mongodb_type 'mongod'
  only_if { allow_mongodb_instance_run }
end
