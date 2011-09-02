maintainer        "edelight GmbH"
maintainer_email  "markus.korn@edelight.de"
license           "Apache 2.0"
description       "Installs and configures mongodb"
version           "0.9"

recipe "mongodb", "Installs and configures a single node mongodb instance"
recipe "mongodb::mongos", "Installs and configures a mongos which can be used in a sharded setup"
recipe "mongodb::configserver", "Installs and configures a configserver for mongodb sharding"
recipe "mongodb::shard", "Installs and configures a single shard"
recipe "mongodb::replicaset", "Installs and configures a mongodb replicaset"

%w{ ubuntu debian }.each do |os|
  supports os
end

attribute "mongodb/dbpath",
  :display_name => "dbpath",
  :description => "Path to store the mongodb data",
  :default => "/var/lib/mongodb"
  
attribute "mongodb/logpath",
  :display_name => "logpath",
  :description => "Path to store the logfiles of a mongodb instance",
  :default => "/var/log/mongodb"
  
attribute "mongodb/port",
  :display_name => "Port",
  :description => "Port the mongodb instance is running on",
  :default => "27017"
  
attribute "mongodb/client_roles",
  :display_name => "Client Roles",
  :description => "Roles of nodes who need access to the mongodb instance",
  :default => []
  
attribute "mongodb/cluster_role_prefix",
  :display_name => "Cluster Role refix",
  :description => "Prefix to identify all members of a mongodb cluster",
  :default => nil

attribute "mongodb/shard_name",
  :display_name => "Shard name",
  :description => "Name of a mongodb shard",
  :default => "default"  
  
attribute "mongodb/sharded_collections",
  :display_name => "Sharded Collections",
  :description => "collections to shard",
  :default => {}
