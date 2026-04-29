# mongodb_config

Writes MongoDB YAML configuration and supporting directories.

## Actions

| Action | Description |
|--------|-------------|
| `:create` | Creates directories, config file, and optional key file. |
| `:delete` | Removes managed files and data directory. |

## Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `instance_name` | String | name | Instance name. |
| `mongodb_type` | String | `'mongod'` | `mongod`, `mongos`, or `configserver`. |
| `config` | Hash | `{}` | MongoDB YAML configuration overrides. |
| `port` | Integer | `27017` | Listen port. |
| `bind_ip` | String | `'0.0.0.0'` | Bind address. |
| `config_path` | String, nil | platform default | Config file path. |
| `data_path` | String, nil | platform default | Data directory for `mongod`. |
| `log_path` | String, nil | config default | Log path. |
| `key_file_content` | String, nil | `nil` | Sensitive key file content. |
| `key_file_path` | String, nil | config value | Key file path. |
| `user` | String, nil | platform default | Owner for data/log/key files. |
| `group` | String, nil | platform default | Group for data/log/key files. |
| `root_group` | String | `'root'` | Group for root-owned config. |

## Example

```ruby
mongodb_config 'mongod' do
  config('storage' => { 'dbPath' => '/srv/mongodb' })
end
```
