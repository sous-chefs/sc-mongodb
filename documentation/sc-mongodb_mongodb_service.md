# mongodb_service

Creates and manages a systemd unit for MongoDB.

## Actions

| Action     | Description                                           |
| ---------- | ----------------------------------------------------- |
| `:create`  | Creates the unit and runs configured service actions. |
| `:delete`  | Stops, disables, and deletes the unit.                |
| `:start`   | Starts the unit.                                      |
| `:stop`    | Stops the unit.                                       |
| `:restart` | Restarts the unit.                                    |

## Properties

| Property          | Type            | Default                     | Description                           |
| ----------------- | --------------- | --------------------------- | ------------------------------------- |
| `service_name`    | String          | name                        | Systemd unit name without `.service`. |
| `mongodb_type`    | String          | `'mongod'`                  | Binary to run, `mongod` or `mongos`.  |
| `config_path`     | String          | type default                | Config file path.                     |
| `user`            | String, nil     | platform default            | Service user.                         |
| `group`           | String, nil     | platform default            | Service group.                        |
| `unit_after`      | Array           | `['network-online.target']` | Systemd `After=` targets.             |
| `unit_wants`      | Array           | `['network-online.target']` | Systemd `Wants=` targets.             |
| `limit_nofile`    | Integer, String | `64000`                     | `LimitNOFILE`.                        |
| `limit_nproc`     | Integer, String | `32000`                     | `LimitNPROC`.                         |
| `service_actions` | Array           | `[:enable, :start]`         | Actions applied after unit creation.  |

## Example

```ruby
mongodb_service 'mongod' do
  config_path '/etc/mongod.conf'
end
```
