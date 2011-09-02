# DESCRIPTION:

Installs and configures various kind of MongoDB setups, including sharding and replication.

# REQUIREMENTS:

## Platform:

The cookbook aims to be platform independant, but is best tested on debian squeze systems.

# DEFINITIONS:

This cookbook contains a definition `mongodb_instance` which can be used to configure
a certain type of mongodb instance, like the default mongodb or various components
of a sharded setup.

For examples see the USAGE section below.

# ATTRIBUTES: 

* `mongodb[:dbpath]` - Location for mongodb data directory, defaults to "/var/lib/mongodb"
* `mongodb[:logpath]` - Path for the logfiles, default is "/var/log/mongodb"
* `mongodb[:port]` - Port the mongod listens on, default is 27017
* `mongodb[:client_role]` - Role identifing all external clients which should have access to a mongod instance
* `mongodb[:cluster_role_prefix]` - Name prefix for all roles used to identify
    all members of a mongodb cluster.
* `mongodb[:shard_name]` - Name of a shard, default is "default"
* `mongodb[:sharded_collections]` - Define which collections are sharded

# USAGE:

To install and run a single mongodb instance, simply add

```ruby
include_recipe "mongodb::default"
```
  
to your recipe. This will run the mongodb instance as configured by your distribution.
By changing the dbpath, logpath and port settings (see ATTRIBUTES) for this node
you will be able to change this defaults.
If you would like to tweak more settings, simply use the `mongodb_instance`
definition, like

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
  dbpath "/data/"
end
```
  
The result is a new system service with

```shell
  /etc/init.d/my_instance <start|stop|restart|status>
```
  
If you would like to add your mongodb instance to a replicaset all you have to
do is adding `mongodb::replicaset` to the node's run_list and make sure to add
one ore more roles with the same prefix to all members of the replicaset. This
prefix has to be defined in `mongodb[:cluster_role_prefix]` . For example you
could create a role called "my_replicaset" and add this role to the run_list of
all nodes which should be in the replicaset. finally you only have to define
`mongodb[:cluster_role_prefix]` for all nodes in this cluster. This way they are
able to find each other.

Configure sharding is a bit more complicated, because you need a few more
components, but the idea is the same: identification of the members with their
different internal roles (mongos, configserver, etc.) is done via
`mongodb[:cluster_role_prefix]` and a `mongodb[:shard_name]`

Let's have a look at a simple sharding setup, consisting of two shard servers, one
config server and one mongos.

First we would like to configure the two shards. For doing so, just use
`mongodb::shard` in the node's run_list and define a unique `mongodb[:shard_name]`
for each of these two nodes, say "shard1" and "shard2".

Then configure a node to act as a config server - by using the `mongodb::configserver`
recipe.

And finally you need to configure the mongos. This can be done by using the
`mongodb::mongos` recipe. The mongos needs some special configuration, as these
mongos are actually doing the configuration of the whole sharded cluster.
Most importantly you need to define a set of `mongodb[:sharded_collections]`
The value of this attribute should look like

```javascript
{
  "test.addressbook": "name",
  "mydatabase.calendar": "date"
}
```
  
Now mongos will automatically enable sharding for the "test" and the "mydatabase"
database. Also the "addressbook" and the "calendar" collection will be sharded,
with sharding key "name" resp. "date".
In the context of a sharding cluster always keep in mind to use roles with the same
prefix, and define this prefix, to identify all members. Also shard names are
important to distinguish the different shards.

This is esp. important when you want to replicate shards. The setup is not much
different to the one described above. all you have to do is adding the 
`mongodb::replicaset` recipe to all shard nodes, and make sure that all shard
nodes which should be in the same replicaset have the same shard name.

# LICENSE and AUTHOR:

Author:: Markus Korn <markus.korn@edelight.de>

Copyright:: 2011, edelight GmbH

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
