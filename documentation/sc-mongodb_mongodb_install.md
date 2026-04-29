# mongodb_install

Installs MongoDB packages from the official repository.

## Actions

| Action | Description |
|--------|-------------|
| `:install` | Creates the repository and installs packages. |
| `:remove` | Removes packages and repository. |

## Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `install_name` | String | name | Resource name. |
| `install_method` | String | `'mongodb-org'` | Use `mongodb-org` or `none`. |
| `repository_name` | String | `'mongodb'` | Repository resource name. |
| `version` | String, Float | `'8.0'` | Repository version. |
| `package_name` | String | `'mongodb-org'` | Package name. |
| `package_version` | String, nil | `nil` | Exact package version. |
| `package_options` | String, nil | platform default | Package manager options. |
| `install_debian_components` | true, false | `true` | Installs Debian component packages. |

## Example

```ruby
mongodb_install 'default' do
  version '8.0'
end
```
