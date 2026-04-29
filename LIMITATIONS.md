# Limitations

## Package Availability

This cookbook targets MongoDB Community Edition packages from MongoDB's official
repositories. MongoDB 8.0 is the baseline for the custom-resource migration.
The source for supported-platform data is the official MongoDB installation
documentation: <https://www.mongodb.com/docs/manual/installation/>.

### APT (Debian/Ubuntu)

* Ubuntu 20.04 LTS "Focal": MongoDB 8.0 packages are available for 64-bit hosts.
* Ubuntu 22.04 LTS "Jammy": MongoDB 8.0 packages are available for 64-bit hosts.
* Ubuntu 24.04 LTS "Noble": MongoDB 8.0 packages are available for 64-bit hosts.
* Debian 12 "Bookworm": MongoDB 8.0 packages are available for x86_64.

Repository URL pattern:

* `https://repo.mongodb.org/apt/ubuntu <codename>/mongodb-org/8.0 multiverse`
* `https://repo.mongodb.org/apt/debian bookworm/mongodb-org/8.0 main`

### DNF/YUM (RHEL family)

* Amazon Linux 2023: MongoDB 8.0 packages are available for 64-bit hosts.
* RHEL, CentOS Stream, Oracle Linux, Rocky Linux, and AlmaLinux 8: MongoDB 8.0
  packages are available for x86_64, with ARM64 support on selected platforms.
* RHEL, CentOS Stream, Oracle Linux, Rocky Linux, and AlmaLinux 9: MongoDB 8.0
  packages are available for x86_64, with ARM64 support on selected platforms.

Repository URL pattern:

* `https://repo.mongodb.org/yum/amazon/2023/mongodb-org/8.0/x86_64/`
* `https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/8.0/$basearch/`

### Zypper (SUSE)

MongoDB does not publish MongoDB 8.0 Community Edition packages for openSUSE
Leap. Do not include openSUSE Leap in the MongoDB 8 migration test matrix.

## Architecture Limitations

MongoDB documents all supported Linux packages as 64-bit only. x86_64 is the
safe baseline for CI. ARM64 is available only on selected MongoDB 8 platforms
and should be added after a dedicated package repository check per platform.

## Source/Compiled Installation

The migration should prefer official `mongodb-org` packages. MongoDB also
publishes `.tgz` tarballs, but tarball installation requires platform-specific
runtime dependencies and separate `mongosh` installation. Source installation is
out of scope for this cookbook migration.

## Known Issues

* MongoDB 8.0 removed support for the legacy `storage.journal.enabled`
  configuration key.
* MongoDB 8.0 uses `mongosh`; tests must not rely on the legacy `mongo` shell.
* Legacy sysvinit and upstart templates are migration blockers. New resources
  should use systemd-only service management.
* MongoDB 6.0 reached end of life on July 31, 2025. Do not use MongoDB 6.0 as
  a baseline for this migration.
* Debian 11 and RHEL 7 are not retained for MongoDB 8.0.
