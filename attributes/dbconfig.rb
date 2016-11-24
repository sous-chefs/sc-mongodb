# All the configuration files that can be dumped
# the attribute-based-configuration
# dump anything into default['mongodb']['config'][<setting>] = <value>
# these options are in the order of mongodb docs

include_attribute 'sc-mongodb::default'

default['mongodb']['config']['net']['port'] = 27_017
default['mongodb']['config']['net']['bindIp'] = '0.0.0.0'

default['mongodb']['config']['systemLog']['destination'] = 'file'
default['mongodb']['config']['systemLog']['logAppend'] = true
default['mongodb']['config']['systemLog']['path'] = '/var/log/mongodb/mongod.log'

case node['platform_family']
when 'rhel', 'fedora'
  default['mongodb']['config']['processManagement']['fork'] = true
  default['mongodb']['config']['processManagement']['pidFilePath'] = '/var/run/mongodb/mongod.pid'
end

default['mongodb']['config']['storage']['journal']['enabled'] = true
default['mongodb']['config']['storage']['dbPath'] = case node['platform_family']
                                                    when 'rhel', 'fedora'
                                                      '/var/lib/mongo'
                                                    else
                                                      '/var/lib/mongodb'
                                                    end

default['mongodb']['config']['storage']['engine'] = 'wiredTiger'

default['mongodb']['config']['replication']['oplogSizeMB'] = nil
default['mongodb']['config']['replication']['replSetName'] = nil
default['mongodb']['config']['replication']['secondaryIndexPrefetch'] = nil
default['mongodb']['config']['replication']['enableMajorityReadConcern'] = nil

default['mongodb']['config']['security']['keyFile'] = '/etc/mongodb.key'
