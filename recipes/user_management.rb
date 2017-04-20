#
# Cookbook Name:: mongodb
# Recipe:: user_management
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

include_recipe 'sc-mongodb::mongo_gem'

users = []
admin = node['mongodb']['admin']

# If authentication is required,
# add the admin to the users array for adding/updating
users << admin if (node['mongodb']['config']['auth'] == true) || (node['mongodb']['mongos_create_admin'] == true)

users.concat(node['mongodb']['users'])

# Add each user specified in attributes
users.each do |user|
  mongodb_user user['username'] do
    password user['password']
    roles user['roles']
    database user['database']
    connection node['mongodb']
    if node.recipe?('sc-mongodb::mongos') || node.recipe?('sc-mongodb::replicaset')
      # If it's a replicaset or mongos, don't make any users until the end
      action :nothing
      subscribes :add, 'ruby_block[config_replicaset]', :delayed
      subscribes :add, 'ruby_block[config_sharding]', :delayed
    else
      action user['action'] || :add
    end
  end
end
