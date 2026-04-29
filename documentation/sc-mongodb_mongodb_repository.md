# mongodb_repository

Manages the official MongoDB package repository.

## Actions

| Action | Description |
|--------|-------------|
| `:create` | Creates the apt or yum repository. |
| `:remove` | Removes the repository. |

## Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `repository_name` | String | name | Repository name. |
| `version` | String, Float | `'8.0'` | MongoDB major repository version. |
| `enabled` | true, false | `true` | Enables yum repository entries. |

## Example

```ruby
mongodb_repository 'mongodb' do
  version '8.0'
end
```
