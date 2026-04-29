# mongodb_user

Creates, modifies, or deletes MongoDB users through the Ruby MongoDB driver.

## Actions

| Action | Description |
|--------|-------------|
| `:add` | Creates the user when missing. |
| `:modify` | Applies the add behavior. |
| `:delete` | Removes the user when present. |

## Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `username` | String | name | MongoDB username. |
| `password` | String | none | Sensitive password. |
| `roles` | Array | `[]` | MongoDB roles. |
| `database` | String | `'admin'` | Database where the user is managed. |
| `connection` | Hash | localhost defaults | Connection and authentication settings. |

## Example

```ruby
mongodb_user 'app' do
  password 'secret'
  roles ['readWrite']
  database 'app'
end
```
