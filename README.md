# sc-MongoDB Cookbook

[![Cookbook Version](https://img.shields.io/cookbook/v/sc-mongodb.svg)](https://supermarket.chef.io/cookbooks/sc-mongodb)
[![CI State](https://github.com/sous-chefs/sc-mongodb/workflows/ci/badge.svg)](https://github.com/sous-chefs/sc-mongodb/actions?query=workflow%3Aci)
[![OpenCollective](https://opencollective.com/sous-chefs/backers/badge.svg)](#backers)
[![OpenCollective](https://opencollective.com/sous-chefs/sponsors/badge.svg)](#sponsors)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](https://opensource.org/licenses/Apache-2.0)

Provides custom resources for installing and configuring MongoDB Community Edition.

## Requirements

### Chef Infra Client

Chef Infra Client 15.3 or later.

### Platforms

This cookbook targets MongoDB 8.0 Community packages on the platforms listed in `metadata.rb`.
See [LIMITATIONS.md](LIMITATIONS.md) for current vendor package limitations.

## Breaking Migration

This cookbook is now a custom-resource cookbook. It no longer ships public recipes,
attributes, or definitions. Existing users must move recipe and node-attribute usage into
wrapper cookbook resource declarations.

See [migration.md](migration.md) for mapping examples.

## Resources

* [mongodb_repository](documentation/sc-mongodb_mongodb_repository.md)
* [mongodb_install](documentation/sc-mongodb_mongodb_install.md)
* [mongodb_config](documentation/sc-mongodb_mongodb_config.md)
* [mongodb_service](documentation/sc-mongodb_mongodb_service.md)
* [mongodb_instance](documentation/sc-mongodb_mongodb_instance.md)
* [mongodb_replicaset](documentation/sc-mongodb_mongodb_replicaset.md)
* [mongodb_sharding](documentation/sc-mongodb_mongodb_sharding.md)
* [mongodb_ruby_gems](documentation/sc-mongodb_mongodb_ruby_gems.md)
* [mongodb_agent](documentation/sc-mongodb_mongodb_agent.md)
* [mongodb_user](documentation/sc-mongodb_mongodb_user.md)

## Examples

### Single Instance

```ruby
mongodb_instance 'mongod' do
  version '8.0'
  action :create
end
```

### Custom Configuration

```ruby
mongodb_instance 'mongod' do
  config(
    'net' => {
      'bindIp' => '127.0.0.1',
      'port' => 27_017,
    },
    'storage' => {
      'dbPath' => '/srv/mongodb',
    }
  )
end
```

### Replicaset

```ruby
mongodb_replicaset 'rs_default' do
  auto_configure false
end
```

### Mongos

```ruby
mongodb_sharding 'router' do
  role 'mongos'
  config(
    'sharding' => {
      'configDB' => 'cfg1.example.com:27019,cfg2.example.com:27019,cfg3.example.com:27019',
    }
  )
  auto_configure false
end
```

### Agent

```ruby
mongodb_agent 'monitoring' do
  api_key 'api-key'
end
```

### User

```ruby
mongodb_ruby_gems 'mongo driver'

mongodb_user 'app' do
  password 'secret'
  roles ['readWrite']
  database 'app'
end
```

## Maintainers

This cookbook is maintained by the Sous Chefs. For more information, visit
[sous-chefs.org](https://sous-chefs.org/) or the Chef Community Slack
[#sous-chefs](https://chefcommunity.slack.com/messages/C2V7B88SF).

## Contributors

This project exists thanks to all the people who contribute.

### Backers

Thank you to all our backers.

![https://opencollective.com/sous-chefs#backers](https://opencollective.com/sous-chefs/backers.svg?width=600&avatarHeight=40)

### Sponsors

Support this project by becoming a sponsor.

![https://opencollective.com/sous-chefs/sponsor/0/website](https://opencollective.com/sous-chefs/sponsor/0/avatar.svg?avatarHeight=100)
