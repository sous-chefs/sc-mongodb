# All the configuration files that can be dumped
# the attribute-based-configuration
# dump anything into default['mongodb']['config']['mongod'][<setting>] = <value>
# these options are in the order of mongodb docs

include_attribute 'sc-mongodb::default'

# mongod defaults
default['mongodb']['config']['mongod']['net']['port'] = 27017
default['mongodb']['config']['mongod']['net']['bindIp'] = '0.0.0.0'

default['mongodb']['config']['mongod']['systemLog']['destination'] = 'file'
default['mongodb']['config']['mongod']['systemLog']['logAppend'] = true
default['mongodb']['config']['mongod']['systemLog']['path'] = '/var/log/mongodb/mongod.log'

case node['platform_family']
when 'rhel', 'fedora'
  default['mongodb']['config']['mongod']['processManagement']['fork'] = true
  default['mongodb']['config']['mongod']['processManagement']['pidFilePath'] = '/var/run/mongodb/mongod.pid'
end

default['mongodb']['config']['mongod']['storage']['journal']['enabled'] = true
default['mongodb']['config']['mongod']['storage']['dbPath'] = case node['platform_family']
                                                              when 'rhel', 'fedora'
                                                                '/var/lib/mongo'
                                                              else
                                                                '/var/lib/mongodb'
                                                              end

default['mongodb']['config']['mongod']['storage']['engine'] = 'wiredTiger'

default['mongodb']['config']['mongod']['replication']['oplogSizeMB'] = nil
default['mongodb']['config']['mongod']['replication']['replSetName'] = nil
default['mongodb']['config']['mongod']['replication']['secondaryIndexPrefetch'] = nil
default['mongodb']['config']['mongod']['replication']['enableMajorityReadConcern'] = nil

default['mongodb']['config']['mongod']['security']['keyFile'] = nil

# mongos defaults
default['mongodb']['config']['mongos']['net']['port'] = 27017
default['mongodb']['config']['mongos']['net']['bindIp'] = '0.0.0.0'

default['mongodb']['config']['mongos']['systemLog']['destination'] = 'file'
default['mongodb']['config']['mongos']['systemLog']['logAppend'] = true
default['mongodb']['config']['mongos']['systemLog']['path'] = '/var/log/mongodb/mongos.log'

case node['platform_family']
when 'rhel', 'fedora'
  default['mongodb']['config']['mongos']['processManagement']['fork'] = true
  default['mongodb']['config']['mongos']['processManagement']['pidFilePath'] = '/var/run/mongodb/mongos.pid'
end

default['mongodb']['config']['mongos']['sharding']['configDB'] = nil

default['mongodb']['config']['mongos']['security']['keyFile'] = nil
