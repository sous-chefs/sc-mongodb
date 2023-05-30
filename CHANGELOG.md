# sc-mongodb Cookbook CHANGELOG

## Unreleased

- Add support for Rocky Linux

## 5.1.14 - *2023-05-17*

## 5.1.13 - *2023-05-03*

## 5.1.12 - *2023-04-07*

Standardise files with files in sous-chefs/repo-management

## 5.1.11 - *2023-04-01*

## 5.1.10 - *2023-04-01*

## 5.1.9 - *2023-04-01*

Standardise files with files in sous-chefs/repo-management

## 5.1.8 - *2023-03-20*

Standardise files with files in sous-chefs/repo-management

## 5.1.7 - *2023-03-15*

Standardise files with files in sous-chefs/repo-management

## 5.1.6 - *2023-02-23*

Standardise files with files in sous-chefs/repo-management

## 5.1.5 - *2023-02-16*

## 5.1.4 - *2023-02-16*

Standardise files with files in sous-chefs/repo-management

Standardise files with files in sous-chefs/repo-management

## 5.1.3 - *2023-02-14*

## 5.1.2 - *2022-12-11*

Standardise files with files in sous-chefs/repo-management

Standardise files with files in sous-chefs/repo-management

## 5.1.1 - *2022-02-17*

- Standardise files with files in sous-chefs/repo-management

## 5.1.0 - *2022-02-10*

- Use chef_gem for replicaset recipe

## 5.0.1 - *2022-02-08*

- Remove delivery folder

## 5.0.0 - *2022-01-07*

- Require Chef >= 15.3 for unified_mode
- resolved cookstyle error: resources/agent.rb:1:1 refactor: `Chef/Deprecations/ResourceWithoutUnifiedTrue`
- resolved cookstyle error: resources/user.rb:1:1 refactor: `Chef/Deprecations/ResourceWithoutUnifiedTrue`

## 4.1.3 - *2022-01-06*

- resolved regression in custom resource names (#272)

## 4.1.2 - *2021-08-30*

- Standardise files with files in sous-chefs/repo-management

## 4.1.1 - *2021-06-01*

- resolved cookstyle error: definitions/mongodb.rb:53:12 convention: `Style/RedundantParentheses`
- resolved cookstyle error: libraries/mongodb_config_helpers.rb:21:5 warning: `ChefDeprecations/UseYamlDump`
- resolved cookstyle error: libraries/user.rb:144:1 convention: `Layout/TrailingWhitespace`
- resolved cookstyle error: libraries/user.rb:144:15 convention: `Style/RedundantBegin`
- resolved cookstyle error: libraries/user.rb:145:13 convention: `Layout/IndentationWidth`
- resolved cookstyle error: libraries/user.rb:146:17 convention: `Layout/IndentationConsistency`
- resolved cookstyle error: libraries/user.rb:147:17 convention: `Layout/IndentationConsistency`
- resolved cookstyle error: libraries/user.rb:149:17 convention: `Layout/IndentationConsistency`
- resolved cookstyle error: libraries/user.rb:166:1 convention: `Layout/TrailingWhitespace`
- resolved cookstyle error: libraries/user.rb:167:1 convention: `Layout/EmptyLines`
- resolved cookstyle error: libraries/user.rb:168:15 convention: `Layout/IndentationConsistency`
- resolved cookstyle error: libraries/user.rb:168:17 convention: `Layout/IndentationConsistency`
- resolved cookstyle error: libraries/user.rb:169:15 convention: `Layout/IndentationConsistency`
- resolved cookstyle error: libraries/user.rb:169:17 convention: `Layout/IndentationConsistency`
- Resolve cookstyle issues
- Comment out ChefSpec until defintions are converted to custom resources
- Disable platforms that do not currently work
- Remove testing on EL6

## 4.0.1

- resolved cookstyle error: recipes/mongodb_org_repo.rb:31:53 convention: `Layout/TrailingWhitespace`
- resolved cookstyle error: recipes/mongodb_org_repo.rb:31:54 refactor: `ChefModernize/FoodcriticComments`

## 4.0.0

- Minimum Chef version 14
- resolved cookstyle error: libraries/user.rb:116:15 refactor: `ChefCorrectness/ChefApplicationFatal`
- resolved cookstyle error: libraries/user.rb:138:11 refactor: `ChefCorrectness/ChefApplicationFatal`
- resolved cookstyle error: libraries/user.rb:172:13 refactor: `ChefCorrectness/ChefApplicationFatal`
- resolved cookstyle error: libraries/user.rb:212:13 refactor: `ChefCorrectness/ChefApplicationFatal`
- resolved cookstyle error: libraries/user.rb:222:15 refactor: `ChefCorrectness/ChefApplicationFatal`
- resolved cookstyle error: metadata.rb:11:1 refactor: `ChefModernize/UnnecessaryDependsChef14`

## v3.0.0

- Update CI tooling to actions
- mongodb.rb (cluster_up_to_date?): optimize
- Fix packages version pin for Debian
- Fix user creation error with MongoDB 4.x
- Simplify the platform checks
- Remove specs for EOL platforms
- Remove deprecated long_description metadata
- Remove if respond_to? usage in metadata.rb
- Remove the ChefSpec converge report

## v2.0.0

- custom resource user resource
- update CI tooling

## v1.2.0

- Fixes issue where on debain based systems mongo is not updated if version is increased
- Correct attribute usage (#186)
- Fix Invalid Keyfile Option (#191)
- Fix for issue where mongo would not upgrade on debian based systems (#181)
- Use pgp keyfiles for debian packages (#193)

## v1.0.1 Changes

- Refactor replicaset configuration

## v1.0.0 Changes (Released 2017-05-23)

_WARNING:_ This is a rewrite that contains many backwards incompatable changes. Many attributes have changed defaults and/or the attribute key itself.

- Drop support for 10gen repo and default to mongo-org repo install
- Remove Chef 10 and 11 support
- Update Mongo default version to 3.2.10
- Drop support for Mongo < 3.0
- Convert all test-kitchen verification to inspec
- Change `node['mongodb']['config']` to have `mongos` and `mongod` keys before actual config setting
- Update apt and yum repo
- Update MMS agent install to deb/rpm packages and add `mongodb_agent` resource
- Fixup relicaset and shard helpers

## v0.18.1 Changes

- Fix cookbook name in attributes file

## v0.18.0 Changes

- Rename cookbook from mongodb to sc-mongodb (no attribute changes, should be 100% compatable with mongodb cookbook on supermarket)

**NOTE** v0.18.0 is the same as v0.17.0 with the exception of the cookbook name. All attributes have keped the `mongodb` namespace while the cookbook has been renamed `sc-mongodb`

## v0.17.0 Changes

- Add ability to use ipaddress instead of fqdn in replicaset
- fix creating user bug for custom host and port
- Add a new install method 'none' that doesn't install.
- Add NUMA support to debian-mongodb upstart script
- Moved the ulimit commands to the start function
- fix for bug #348 - broken sharding
- Get rid of chef_gem
- Excluded Amazon Linux from using systemctl
- pessimistically allow 1.X mongo gem
- add custom repo support
- Moved the running of the sysconfig_file above the NUMA support
- replace deprecated recipe
- bug fix in member_config for having _id > 255
- User management in replicasets / sharding
- Force rs.reconfig when there are no old members
- Packager Options Attribute

## v0.16.3 Changes (release never tagged, rolled into `v0.17.0` release)

- remove old runit dependency
- fix user/group attribute variables for newer versions of EL and Fedora

## v0.16.2 (Release Tue Nov 4 11:48:54 PST 2014)

- start doing even patches = release, odd = dev.
- removed unmaintained freebsd support file
- pass `--force-yes` to apt to bypass issue with package/config conflict #305
- bumped mms_agent version for `monitoring` and `backup` #312
- added user management/auth support, and patches #313, #317
- fix patches on logpath #310
- allow changing mongos service name #319
- update upstart config for debian #323
- added fixes for installation prereqs, sasl
- fix systemd usecase for redhat (#352, #350)

## v0.16.1

- remove old `mms_agent.rb` and `mms-agent.rb` in favor of new mms_*_agent.rb
- Update mms_*_agent.rb to use template instead of ruby-block, nothing, but call restart
- DEPRECATE '10gen_repo' for 'mongodb_org_repo' #287
- node['mongodb']['install_method'] can now be '10gen' (DEPRECATE) or 'mongodb_org'
- allow `node['mongodb']['config']['logpath'] to be nil for syslog #288

## v0.16.0

- BREAKING CHANGE - drop support for Ruby < 1.9, Chef < 11
- cookbook dependency change

  - yum >= 3.0
  - remove <= limit for all other dep

- update to Berkshelf 3

- # 280 fix install for centos (missing build-essentials)

## v0.15.2 End of Ruby 1.8, Chef 10 support

- update test-kitchen for mongos
- update MMS version
- update rubocop
- minor typo fixes

## v0.15.1

- 'potentially' BREAKING CHANGES, cookbook dependency pinned

  - yum < 3.0
  - runit < 1.5
  - python < 1.4.5

- DEPRECATION: explicitly drop support for 'unsupported' platforms

  - must be freebsd, rhel, fedora, debian

- DEPRECATION: recipe mms-agent.rb/mms_agent.rb

  - see #261 for new-recipes

- use node.set to make sure is_* attributes are available for search

- 'key_file' -> 'key_file_content'

- allow pinning for gems, pip packages

- # 261 new mms agent recipe based on new packaging in upstream

- # 256 Allow mms_agent to be run as non-root user

  - replSet is not set automatically

## v0.15.0

- DEPRECATION: backward compatability for dbconfig variables in node['mongodb']

  - use node['mongodb']['config'][variable] = value

## v0.14.10 DEVELOPMENTAL RELEASE

- Final 0.14 release
- move node['mongodb']['config']['configsrv'] auto update to the top
- Drop using Chef.Version as it is not rc/beta compatible
- installs gem bson_ext

## v0.14.8 DEVELOPMENTAL RELEASE

- Rubocop (cherry pick of #220)

## v0.14.7 DEVELOPMENTAL RELEASE

- Automatically install bson_ext gem
- Add check/protection for empty shard
- Force node['mongodb']['config']['configsrv'] == true when set as configserver

## v0.14.6 DEVELOPMENTAL RELEASE

- try to autoconfigure 'configsrv' from configserver_nodes
- remove `include 'mongodb::default'` from definition
- allow chef-run without restarting mongo
- comment cleanup

## v0.14.X DEVELOPMENTAL RELEASES

- Split out install into separate recipe
- Adds more testing
- Fixes mms-agent installation/runtime
- Preliminary Work being done to convert completely to Resource style
- patches to Replicaset
- patches to fix upstart service
- patches to configserver install

## v0.13.2, RELEASED

- add support for chef_gem on newer versions of chef

## v0.13.1, RELEASED

- Add keyfileSupport

## v0.13.0, RELEASED

- Bunch of stuff...

## v0.1.0

Initial release of the cookbooks for the chef configuration management system developed at edelight GmbH. With this first release we publish the mongodb cookbook we use for our systems. This cookbook helps you to configure single node mongodb instances as well as more complicated cluster setups (including sharding and replication).
