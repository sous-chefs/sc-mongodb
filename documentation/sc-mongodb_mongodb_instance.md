# mongodb_instance

High-level resource that installs, configures, and starts one MongoDB instance.

## Actions

| Action | Description |
|--------|-------------|
| `:create` | Installs packages, writes config, and manages service. |
| `:delete` | Deletes service/config and removes packages when `install true`. |

## Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `instance_name` | String | name | Instance and service name. |
| `mongodb_type` | String | `'mongod'` | `mongod`, `mongos`, or `configserver`. |
| `version` | String, Float | `'8.0'` | Repository version. |
| `package_version` | String, nil | `nil` | Exact package version. |
| `package_name` | String | `'mongodb-org'` | Package name. |
| `config` | Hash | `{}` | MongoDB config overrides. |
| `port` | Integer | `27017` | Listen port. |
| `bind_ip` | String | `'0.0.0.0'` | Bind address. |
| `config_path` | String, nil | type default | Config file path. |
| `user` | String, nil | platform default | Service/data user. |
| `group` | String, nil | platform default | Service/data group. |
| `install` | true, false | `true` | Whether to manage packages. |
| `service_actions` | Array | `[:enable, :start]` | Service actions. |
| `replicaset_name` | String, nil | `nil` | Replicaset name. |
| `replicaset` | true, false | `false` | Enables replicaset config. |
| `shard` | true, false | `false` | Enables shard server config. |
| `configservers` | Array | `[]` | Config server nodes for `mongos`. |
| `data_path` | String, nil | platform default | Data directory. |
| `key_file_content` | String, nil | `nil` | Sensitive key file content. |

## Example

```ruby
mongodb_instance 'mongod' do
  version '8.0'
end
```
