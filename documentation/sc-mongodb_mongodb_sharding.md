# mongodb_sharding

Configures MongoDB config server, shard, or mongos roles.

## Actions

| Action    | Description                         |
| --------- | ----------------------------------- |
| `:create` | Creates the selected sharding role. |
| `:delete` | Deletes the managed instance.       |

## Properties

| Property              | Type          | Default                   | Description                             |
| --------------------- | ------------- | ------------------------- | --------------------------------------- |
| `sharding_name`       | String        | name                      | Resource name.                          |
| `role`                | String        | `'mongos'`                | `configserver`, `shard`, or `mongos`.   |
| `cluster_name`        | String, nil   | `nil`                     | Cluster identifier for wrapper logic.   |
| `shard_name`          | String        | `'default'`               | Shard identifier.                       |
| `version`             | String, Float | `'8.0'`                   | Repository version.                     |
| `package_version`     | String, nil   | `nil`                     | Exact package version.                  |
| `config`              | Hash          | `{}`                      | MongoDB config overrides.               |
| `port`                | Integer       | `27017`                   | Listen port.                            |
| `bind_ip`             | String        | `'0.0.0.0'`               | Bind address.                           |
| `replicaset_name`     | String, nil   | `nil`                     | Replicaset name for shard role.         |
| `configservers`       | Array         | `[]`                      | Config server node hashes for `mongos`. |
| `shards`              | Array         | `[]`                      | Shard strings for `addShard`.           |
| `sharded_collections` | Hash          | `{}`                      | Collection-to-key sharding map.         |
| `auto_configure`      | true, false   | `true`                    | Runs sharding commands for `mongos`.    |
| `ruby_gems`           | Hash          | `{ 'mongo' => '~> 2.0' }` | Gems needed for sharding commands.      |

## Example

```ruby
mongodb_sharding 'router' do
  role 'mongos'
  config('sharding' => { 'configDB' => 'cfg1.example.com:27019' })
  auto_configure false
end
```
