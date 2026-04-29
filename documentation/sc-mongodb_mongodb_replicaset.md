# mongodb_replicaset

Configures a MongoDB instance for replicaset use and can initialize the set.

## Actions

| Action | Description |
|--------|-------------|
| `:create` | Installs Ruby driver, creates `mongod`, and optionally configures the set. |
| `:delete` | Removes the managed instance. |

## Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `replicaset_name` | String | name | Replicaset name. |
| `members` | Array | `[]` | Member node hashes for initialization. |
| `auto_configure` | true, false | `true` | Runs replicaset initialization. |
| `version` | String, Float | `'8.0'` | Repository version. |
| `package_version` | String, nil | `nil` | Exact package version. |
| `config` | Hash | `{}` | MongoDB config overrides. |
| `port` | Integer | `27017` | Listen port. |
| `bind_ip` | String | `'0.0.0.0'` | Bind address. |
| `ruby_gems` | Hash | `{ 'mongo' => '~> 2.0' }` | Gems needed for initialization. |

## Example

```ruby
mongodb_replicaset 'rs_default' do
  auto_configure false
end
```
