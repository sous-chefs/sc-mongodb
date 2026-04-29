# mongodb_ruby_gems

Installs Ruby gems needed for MongoDB administrative resources.

## Actions

| Action | Description |
|--------|-------------|
| `:install` | Installs build packages and chef gems. |
| `:remove` | Removes chef gems. |

## Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `gem_set` | String | name | Resource name. |
| `gems` | Hash | `{ 'mongo' => '~> 2.0' }` | Gem names and versions. |
| `install_build_packages` | true, false | `true` | Installs native build dependencies. |

## Example

```ruby
mongodb_ruby_gems 'mongo driver' do
  gems('mongo' => '~> 2.0')
end
```
