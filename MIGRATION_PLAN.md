# Custom Resource Migration Plan

## Current Branch State

Branch `custom-resource-migration` preserves the local release workflow commit
`4c88b90` and adds two safe migration commits:

* `11135a6 chore: normalize mongodb migration baseline`
* `acd9100 feat: add mongodb repository resource`

The cookbook is not fully migrated yet. Recipes and attributes remain for
backward-compatible convergence while resources are extracted.

## Pull Request Overlap

PR #321 (`MongoDB 8.0 compatibility`) overlaps with the migration in these
areas:

* Package default should move from MongoDB 7 to MongoDB 8.
* Ruby driver constraint should move from `mongo ~> 1.12` to a modern 2.x line.
* `storage.journal.enabled` must be removed because MongoDB 8 rejects it.
* InSpec tests must use `mongosh`, not `mongo`.

Do not copy PR #321's Kitchen platform changes directly. They are based on the
old Vagrant matrix and predate the current Dokken/systemd baseline.

## Next Implementation Steps

1. Add shared property partials under `resources/_partial/` for package,
   config, ownership, service, replica, shard, and user-management defaults.
2. Extract `recipes/mongo_gem.rb` into a `mongodb_ruby_gems` resource and update
   `mongodb_user` to assume the Mongo Ruby driver 2.x API.
3. Extract package installation and key-file handling from `recipes/install.rb`
   into `mongodb_install`.
4. Replace `definitions/mongodb.rb` with a flat `mongodb_instance` resource that
   uses systemd-only service management.
5. Split instance concerns into smaller resources where practical:
   `mongodb_config`, `mongodb_service`, `mongodb_replicaset`, and
   `mongodb_sharding`.
6. Convert the MMS agent recipes into test cookbook examples around the existing
   `mongodb_agent` resource, then remove the recipes.
7. Move all recipe examples to `test/cookbooks/test/recipes/`; update Kitchen
   suites to use those recipes instead of cookbook recipes.
8. Delete `recipes/`, `attributes/`, legacy init/upstart templates, and the
   legacy definition once equivalent resources and tests exist.
9. Rewrite documentation from attribute/recipe usage to resource usage.

## Verification Required Before PR

Run and capture these gates after the full migration:

* `berks install`
* `cookstyle`
* `chef exec ruby -c resources/*.rb`
* `chef exec rspec --format documentation`
* `KITCHEN_LOCAL_YAML=kitchen.dokken.yml kitchen test default-ubuntu-2404 --destroy=always`

Before opening a PR, run a structural audit proving that `recipes/` and
`attributes/` are gone and that resource specs exist for every resource.

## Known Blockers

* Full migration requires MongoDB Ruby driver API work in `libraries/mongodb.rb`
  and `libraries/user.rb`; those helpers still contain 1.x-era connection calls.
* `definitions/mongodb.rb` mixes config mutation, search, service notification,
  replica configuration, and sharding, so it should not be lifted wholesale into
  one resource without tests.
* Integration profiles still use legacy paths and several still invoke `mongo`.
* Legacy sysvinit/upstart templates must be removed in favor of systemd, but
  this changes service behavior and needs Kitchen coverage.
