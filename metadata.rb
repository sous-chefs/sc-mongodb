name              'sc-mongodb'
maintainer        'Sous Chefs'
maintainer_email  'help@sous-chefs.org'
license           'Apache-2.0'
description       'Installs and configures mongodb'
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           '1.0.2'

recipe 'sc-mongodb', 'Installs and configures a single node mongodb instance'
recipe 'sc-mongodb::mongos', 'Installs and configures a mongos which can be used in a sharded setup'
recipe 'sc-mongodb::configserver', 'Installs and configures a configserver for mongodb sharding'
recipe 'sc-mongodb::shard', 'Installs and configures a single shard'
recipe 'sc-mongodb::replicaset', 'Installs and configures a mongodb replicaset'
recipe 'sc-mongodb::mms_monitoring_agent', 'Installs and configures a MongoDB MMS Monitoring Agent'
recipe 'sc-mongodb::mms_backup_agent', 'Installs and configures a MongoDB MMS Backup Agent'

depends 'apt', '>= 1.8.2'
depends 'yum', '>= 3.0'
depends 'build-essential', '>= 5.0.0'

%w(
  amazon
  centos
  debian
  oracle
  redhat
  ubuntu
).each do |os|
  supports os
end

source_url 'https://github.com/sous-chefs/mongodb' if respond_to?(:source_url)
issues_url 'https://github.com/sous-chefs/mongodb/issues' if respond_to?(:issues_url)
chef_version '>= 12.5' if respond_to?(:chef_version)
