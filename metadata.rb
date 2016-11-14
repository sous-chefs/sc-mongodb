name              'mongodb'
maintainer        'edelight GmbH'
maintainer_email  'markus.korn@edelight.de'
license           'Apache 2.0'
description       'Installs and configures mongodb'
version           '0.16.3'

depends 'apt', '>= 1.8.2'
depends 'yum', '>= 3.0'
depends 'python'

%w(ubuntu debian centos redhat amazon).each do |os|
  supports os
end

source_url 'https://github.com/chef-brigade/mongodb-cookbook' if respond_to?(:source_url)
issues_url 'https://github.com/chef-brigade/mongodb-cookbook/issues' if respond_to?(:issues_url)
chef_version '>= 11.0' if respond_to?(:chef_version)
