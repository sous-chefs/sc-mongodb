#
# Cookbook Name:: sc-mongodb
# Attributes:: default
#
# Copyright 2010, edelight GmbH
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

# cluster identifier
default['mongodb']['client_roles'] = []
default['mongodb']['cluster_name'] = nil
default['mongodb']['shard_name'] = 'default'

# replica options
default['mongodb']['replica_arbiter_only'] = false
default['mongodb']['replica_build_indexes'] = true
default['mongodb']['replica_hidden'] = false
default['mongodb']['replica_slave_delay'] = 0
default['mongodb']['replica_priority'] = 1
default['mongodb']['replica_tags'] = {}
default['mongodb']['replica_votes'] = 1

default['mongodb']['auto_configure']['replicaset'] = true
default['mongodb']['auto_configure']['sharding'] = true

# don't use the node's fqdn, but this url instead; something like 'ec2-x-y-z-z.aws.com' or 'cs1.domain.com' (no port)
# if not provided, will fall back to the FQDN
default['mongodb']['configserver_url'] = nil

default['mongodb']['root_group'] = 'root'
default['mongodb']['user'] = 'mongodb'
default['mongodb']['group'] = 'mongodb'

default['mongodb']['init_dir'] = '/etc/init.d'
default['mongodb']['init_script_template'] = 'debian-mongodb.init.erb'
default['mongodb']['sysconfig_file']['mongod'] = '/etc/default/mongodb'
default['mongodb']['sysconfig_file']['mongos'] = '/etc/default/mongos'
default['mongodb']['sysconfig_file']['template'] = 'mongodb.sysconfig.erb'

default['mongodb']['dbconfig_file']['template'] = 'mongodb.conf.erb'
default['mongodb']['dbconfig_file']['mongod'] = '/etc/mongod.conf'
default['mongodb']['dbconfig_file']['mongos'] = '/etc/mongos.conf'

default['mongodb']['package_name'] = 'mongodb'
default['mongodb']['package_version'] = '3.2.18'

default['mongodb']['default_init_name'] = 'mongod'
default['mongodb']['instance_name']['mongod'] = 'mongod'
default['mongodb']['instance_name']['mongos'] = 'mongos'

case node['platform_family'] # rubocop:disable Style/ConditionalAssignment
when 'debian'
  # this options lets us bypass complaint of pre-existing init file
  # necessary until upstream fixes ENABLE_MONGOD/DB flag
  default['mongodb']['packager_options'] = '-o Dpkg::Options::="--force-confold" --force-yes'
when 'rhel'
  # Add --nogpgcheck option when package is signed
  # see: https://jira.mongodb.org/browse/SERVER-8770
  default['mongodb']['packager_options'] = '--nogpgcheck'
else
  default['mongodb']['packager_options'] = ''
end

# this option can be "mongodb-org" or "none"
default['mongodb']['install_method'] = 'mongodb-org'

default['mongodb']['is_replicaset'] = nil
default['mongodb']['is_shard'] = nil
default['mongodb']['is_configserver'] = nil

default['mongodb']['reload_action'] = 'restart' # or "nothing"

case node['platform_family']
when 'rhel', 'fedora'
  # determine the package name
  # from http://rpm.pbone.net/index.php3?stat=3&limit=1&srodzaj=3&dl=40&search=mongodb
  # verified for RHEL5,6 Fedora 18,19
  default['mongodb']['package_name'] = 'mongodb-org'
  default['mongodb']['sysconfig_file']['mongod'] = '/etc/sysconfig/mongodb'
  default['mongodb']['user'] = 'mongod'
  default['mongodb']['group'] = 'mongod'
  default['mongodb']['init_script_template'] = 'redhat-mongodb.init.erb'
when 'debian'
  if node['platform'] == 'ubuntu'
    default['mongodb']['repo'] = 'http://repo.mongodb.org/apt/ubuntu'

    # Upstart
    if node['platform_version'].to_f < 15.04
      default['mongodb']['init_dir'] = '/etc/init/'
      default['mongodb']['init_script_template'] = 'debian-mongodb.upstart.erb'
    end
  elsif node['platform'] == 'debian'
    default['mongodb']['repo'] = 'http://repo.mongodb.org/apt/debian'
  end
else
  Chef::Log.error("Unsupported Platform Family: #{node['platform_family']}")
end

default['mongodb']['template_cookbook'] = 'sc-mongodb'

default['mongodb']['key_file_content'] = nil

# install the mongo and bson_ext ruby gems at compile time to make them globally available
# TODO: remove bson_ext once mongo gem supports bson >= 2
default['mongodb']['ruby_gems'] = {
  mongo: '~> 1.12',
  bson_ext: nil,
}
