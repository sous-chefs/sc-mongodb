# Migration Guide

This release is a breaking full custom resource migration. The cookbook no longer
provides public recipes, attributes, or the legacy `mongodb_instance` definition.

## What Changed

* `recipes/` was removed. Use resources from a wrapper cookbook or policy recipe.
* `attributes/` was removed. Configure resources with explicit properties.
* `definitions/` was removed. `mongodb_instance` is now a custom resource.
* Legacy sysvinit and upstart templates were removed. Services are managed with systemd.
* MongoDB 8.0 is the baseline package repository version.

## Common Mappings

### `include_recipe 'sc-mongodb::default'`

```ruby
mongodb_instance 'mongod' do
  version '8.0'
  action :create
end
```

### `node['mongodb']['config']`

Move configuration into the `config` property:

```ruby
mongodb_instance 'mongod' do
  config(
    'net' => {
      'bindIp' => '127.0.0.1',
      'port' => 27_017,
    },
    'storage' => {
      'dbPath' => '/srv/mongodb',
    }
  )
end
```

### `sc-mongodb::replicaset`

```ruby
mongodb_replicaset 'rs_default' do
  auto_configure false
end
```

Pass `members` and leave `auto_configure true` when the wrapper cookbook has the
member data needed to initialize the set.

### `sc-mongodb::configserver`, `sc-mongodb::shard`, and `sc-mongodb::mongos`

```ruby
mongodb_sharding 'configserver' do
  role 'configserver'
  port 27_019
end

mongodb_sharding 'shard1' do
  role 'shard'
  replicaset_name 'rs_shard1'
end

mongodb_sharding 'router' do
  role 'mongos'
  config(
    'sharding' => {
      'configDB' => 'cfg1.example.com:27019,cfg2.example.com:27019,cfg3.example.com:27019',
    }
  )
  auto_configure false
end
```

### `sc-mongodb::mongo_gem`

```ruby
mongodb_ruby_gems 'mongo driver' do
  gems('mongo' => '~> 2.0')
end
```

### MMS Agent Recipes

```ruby
mongodb_agent 'monitoring' do
  api_key 'api-key'
end
```

Use `automation`, `backup`, or `monitoring` as the resource name.

### `sc-mongodb::user_management`

```ruby
mongodb_ruby_gems 'mongo driver'

mongodb_user 'app' do
  password 'secret'
  roles ['readWrite']
  database 'app'
  connection(
    'host' => 'localhost',
    'port' => 27_017,
    'authentication' => {
      'username' => 'admin',
      'password' => 'admin-password',
    }
  )
end
```

Do not store production passwords in plain node attributes. Use your wrapper
cookbook's secret-management pattern.

## Test Cookbook Examples

Runnable examples live in `test/cookbooks/test/recipes/`.
