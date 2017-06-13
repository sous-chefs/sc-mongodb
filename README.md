# sc-MongoDB Cookbook

[![Build Status](https://travis-ci.org/sous-chefs/mongodb.svg)](https://travis-ci.org/sous-chefs/mongodb)

Installs and configures MongoDB

## Supports:

* Single MongoDB instance
* Replication
* Sharding
* Replication and Sharding
* MongoDB Monitoring System

## Community

Live discussion happens on [![Chef Community Slack](https://community-slack.chef.io/badge.svg)](https://community-slack.chef.io/) in [#sous-chefs](https://chefcommunity.slack.com/messages/sous-chefs/).

## REQUIREMENTS:

This cookbook depends on these external cookbooks

- apt
- python
- yum

As of 1.0 This Cookbook requires

- Chef > 12.5
- Ruby > 2.3

As of 0.16 This Cookbook requires

- Chef > 11
- Ruby > 1.9

### Platform:

Currently we 'actively' test using test-kitchen on Ubuntu, Debian, CentOS, Redhat

## DEFINITIONS:

This cookbook contains a definition `mongodb_instance` which can be used to configure
a certain type of mongodb instance, like the default mongodb or various components
of a sharded setup.

For examples see the USAGE section below.

## ATTRIBUTES:

### MongoDB setup

* `default['mongodb']['install_method']` - This option can be "mongodb-org" or "none" - Default ("mongodb-org")

### MongoDB Configuration

The `node['mongodb']['config']` is split into 2 keys, `mongod` and `mongos` (i.e. node['mongodb']['config']['mongod']). They attributes are rendered out as a yaml config file. All settings defined in the Configuration File Options documentation page can be added to the `node['mongodb']['config'][<setting>]` attribute: https://docs.mongodb.com/manual/reference/configuration-options/

Several important attributes to note:

* `node['mongodb']['config']['mongod']['net']['bindIp']` - Configure from which address to accept connections
* `node['mongodb']['config']['mongod']['net']['port']` - Port the mongod listens on, default is 27017
* `node['mongodb']['config']['mongod']['replication']['oplogSizeMB']` - Specifies a maximum size in megabytes for the replication operation log
* `node['mongodb']['config']['mongod']['storage']['dbPath']` - Location for mongodb data directory, defaults to "/var/lib/mongodb"
* `node['mongodb']['config']['mongod']['storage']['engine']` - Storage engine to use, default is `"wiredTiger"`
* `node['mongodb']['config']['mongod']['systemLog']['path']` - Path for the logfiles, default is `"/var/lib/mongo"` for `rhel` and `fedora` and `"/var/log/mongodb/mongod.log"` for all others
* `node['mongodb']['config']['mongod'][<setting>]` - General MongoDB Configuration File option

### Cookbook specific attributes

* `node['mongodb']['reload_action']` - Action to take when MongoDB conf files are modified, default is `"restart"`
* `node['mongodb']['package_version']` - Version of the MongoDB package to install, default is nil
* `node['mongodb']['client_roles']` - Role identifying all external clients which should have access to a mongod instance

### Sharding and replication attributes

* `node['mongodb']['config']['mongod']['replication']['replSetName']` - Define name of replicaset
* `node['mongodb']['cluster_name']` - Name of the cluster, all members of the cluster must reference to the same name, as this name is used internally to identify all members of a cluster.
* `node['mongodb']['shard_name']` - Name of a shard, default is "default"
* `node['mongodb']['sharded_collections']` - Define which collections are sharded
* `node['mongodb']['replica_arbiter_only']` - Set to true to make node an [arbiter](http://docs.mongodb.org/manual/reference/replica-configuration/#local.system.replset.members[n].arbiterOnly).
* `node['mongodb']['replica_build_indexes']` - Set to false to omit [index creation](http://docs.mongodb.org/manual/reference/replica-configuration/#local.system.replset.members[n].buildIndexes).
* `node['mongodb']['replica_hidden']` - Set to true to [hide](http://docs.mongodb.org/manual/reference/replica-configuration/#local.system.replset.members[n].hidden) node from replicaset.
* `node['mongodb']['replica_slave_delay']` - Number of seconds to [delay slave replication](http://docs.mongodb.org/manual/reference/replica-configuration/#local.system.replset.members[n].slaveDelay).
* `node['mongodb']['replica_priority']` - Node [priority](http://docs.mongodb.org/manual/reference/replica-configuration/#local.system.replset.members[n].priority).
* `node['mongodb']['replica_tags']` - Node [tags](http://docs.mongodb.org/manual/reference/replica-configuration/#local.system.replset.members[n].tags).
* `node['mongodb']['replica_votes']` - Number of [votes](http://docs.mongodb.org/manual/reference/replica-configuration/#local.system.replset.members[n].votes) node will cast in an election.


### shared MMS Agent attributes

* `node['mongodb']['mms_agent']['api_key']` - MMS Agent API Key. No default, required.
* `node['mongodb']['mms_agent']['automation']['config'][<setting>]` - General MongoDB MMS Automation Agent configuration file option.
* `node['mongodb']['mms_agent']['backup']['config'][<setting>]` - General MongoDB MMS Monitoring Agent configuration file option.
* `node['mongodb']['mms_agent']['monitoring']['config'][<setting>]` - General MongoDB MMS Monitoring Agent configuration file option.

#### Automation Agent Settings

The defaults values installed by the package are:

```
mmsBaseUrl=https://mms.mongodb.com
logFile=/var/log/mongodb-mms-automation/automation-agent.log
mmsConfigBackup=/var/lib/mongodb-mms-automation/mms-cluster-config-backup.json
logLevel=INFO
maxLogFiles=10
maxLogFileSize=268435456
```

#### Backup Agent Settings

The defaults values installed by the package are:

```
mothership=api-backup.mongodb.com
https=true
```

#### Monitoring Agent Settings

The defaults values installed by the package are:

```
mmsBaseUrl=https://mms.mongodb.com
```

### User management attributes

* `node['mongodb']['config']['auth']` - Require authentication to access or modify the database (`True` or `False`), Default is `nil`
* `node['mongodb']['admin']` - The admin user with userAdmin privileges that allows user management
* `node['mongodb']['users']` - Array of users to add when running the user management recipe

## USAGE:

### Single mongodb instance

Simply add

```ruby
include_recipe "sc-mongodb::default"
```

to your recipe. This will run the mongodb instance as configured by your distribution.
You can change the dbpath, logpath and port settings (see ATTRIBUTES) for this node by
using the `mongodb_instance` definition:

```ruby
mongodb_instance "mongodb" do
  port node['application']['port']
end
```

This definition also allows you to run another mongod instance with a different
name on the same node

```ruby
mongodb_instance "my_instance" do
  port node['mongodb']['port'] + 100
end
```

The result is a new system service with

```shell
  /etc/init.d/my_instance <start|stop|restart|status>
```

### Replicasets

Add `sc-mongodb::replicaset` (instead of `sc-mongodb::default`) to the node's run_list. Also choose a name for your
replicaset cluster and set the value of `node['mongodb']['cluster_name']` for each
member to this name.

The recipe will try to configure the replicaset with the instances already registered in your chef-server with the same 
`node['mongodb']['cluster_name']`, to configure various machines with the replicaset you'll need to deactivate the 
automatic configuration with `node['mongodb']['auto_configure']['replicaset'] = false` and enable that flag only on the last
instance of the replicaset.

### Sharding

You need a few more components, but the idea is the same: identification of the
members with their different internal roles (mongos, configserver, etc.) is done via
the `node['mongodb']['cluster_name']` and `node['mongodb']['shard_name']` attributes.

Let's have a look at a simple sharding setup, consisting of two shard servers, one
config server and one mongos.

First we would like to configure the two shards. For doing so, just use
`sc-mongodb::shard` in the node's run_list and define a unique `mongodb['shard_name']`
for each of these two nodes, say "shard1" and "shard2".

Then configure a node to act as a config server - by using the `sc-mongodb::configserver`
recipe.

And finally you need to configure the mongos. This can be done by using the
`sc-mongodb::mongos` recipe. The mongos needs some special configuration, as these
mongos are actually doing the configuration of the whole sharded cluster.
Most importantly you need to define what collections should be sharded by setting the
attribute `mongodb['sharded_collections']`:

```ruby
{
  "mongodb": {
    "sharded_collections": {
      "test.addressbook": "name",
      "mydatabase.calendar": "date"
    }
  }
}
```

Now mongos will automatically enable sharding for the "test" and the "mydatabase"
database. Also the "addressbook" and the "calendar" collection will be sharded,
with sharding key "name" resp. "date".
In the context of a sharding cluster always keep in mind to use a single role
which is added to all members of the cluster to identify all member nodes.
Also shard names are important to distinguish the different shards.
This is esp. important when you want to replicate shards.

### Sharding + Replication

The setup is not much different to the one described above. All you have to do is add the
`sc-mongodb::replicaset` recipe to all shard nodes, and make sure that all shard
nodes which should be in the same replicaset have the same shard name.

For more details, you can find a [tutorial for Sharding + Replication](https://github.com/edelight/chef-mongodb/wiki/MongoDB%3A-Replication%2BSharding) in the wiki.

### MMS Agent

This cookbook also includes support for
[MongoDB Monitoring System (MMS)](https://mms.mongodb.com/)
agent. MMS is a hosted monitoring service, provided by MongoDB, Inc. Once
the small agent program is installed on the MongoDB host, it
automatically collects the metrics and uploads them to the MMS server.
The graphs of these metrics are shown on the web page. It helps a lot
for tackling MongoDB related problems, so MMS is the baseline for all
production MongoDB deployments.


To setup MMS, simply set your keys in
`node['mongodb']['mms_agent']['api_key']` and then add the
`sc-mongodb::mms_monitoring_agent` recipe to your run list. Your current keys
should be available at your [MMS Settings page](https://mms.mongodb.com/settings).

The agent install and configurations is also available via a custom resource for
wrapper cookbooks.  This allows for further customization outside of this
cookbook

```ruby
mongodb_agent 'monitoring' do
  config {} # Key and value pairs that will be in the config file
  group 'group' # Group to own the config file
  package_url 'package_url' # Download URL of the agent package
  user 'user' # User to own the config file
end
```

### User Management

**NOTE:** Using the `sc-mongodb::user_management` is not secure since passwords are stored plain
text in your node attributes.  Please concider using a wrapper recipe with encrypted data bags
when using this cookbook in production.

An optional recipe is `sc-mongodb::user_management` which will enable authentication in
the configuration file by default and create any users in the `node['mongodb']['users']`.
The users array expects a hash of username, password, roles, and database. Roles should be
an array of roles the user should have on the database given.

By default, authentication is not required on the database. This can be overridden by setting
the `node['mongodb']['config']['auth']` attribute to true in the chef json.

If the auth configuration is true, it will try to create the `node['mongodb']['admin']` user, or
update them if they already exist. Before using on a new database, ensure you're overwriting
the `node['mongodb']['authentication']['username']` and `node['mongodb']['authentication']['password']` to
something besides their default values.

To update the admin username or password after already having deployed the recipe with authentication
as required, simply change `node['mongodb']['admin']['password']` to the new password while keeping the
value of `node['mongodb']['authentication']['password']` the old value. After the recipe runs successfully,
be sure to change the latter variable to the new password so that subsequent attempts to authenticate will
work.

There's also a user resource which has the actions `:add`, `:modify` and `:delete`. If modify is
used on a user that doesn't exist, it will be added. If add is used on a user that exists, it
will be modified.

If using this recipe with replication and sharding, ensure that the `node['mongodb']['key_file_content']`
is set. All nodes must have the same key file in order for the replica set to initialize successfully
when authentication is required. For mongos instances, set `node['mongodb']['mongos_create_admin']` to
`true` to force the creation of the admin user on mongos instances.

# LICENSE and AUTHOR:

## Original Author
- Author:: Markus Korn <markus.korn@edelight.de> via https://github.com/edelight/chef-mongodb

## Current Maintainers

- Maintainer:: Pierce Moore <me@prex.io>
- Maintainer Community:: Sous Chefs [help@sous-chefs.org](mailto:help@sous-chefs.org)

Copyright:: 2011-2014, edelight GmbH

```
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
