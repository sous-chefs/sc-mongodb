# mongodb_agent

Installs and configures MongoDB Cloud Manager/Ops Manager agents.

## Actions

| Action | Description |
|--------|-------------|
| `:create` | Downloads, installs, configures, enables, and starts the agent. |
| `:delete` | Stops, disables, removes package, and deletes config/cache file. |

## Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `type` | String | name | `automation`, `backup`, or `monitoring`. |
| `api_key` | String, nil | `nil` | Sensitive MMS API key. |
| `config` | Hash | `{}` | Agent config overrides. |
| `group` | String, nil | type default | Config file group. |
| `package_url` | String, nil | platform default | Agent package URL. |
| `user` | String, nil | type default | Config file owner. |

## Example

```ruby
mongodb_agent 'monitoring' do
  api_key 'api-key'
end
```
