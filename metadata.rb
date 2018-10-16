name              'sc-mongodb'
maintainer        'Sous Chefs'
maintainer_email  'help@sous-chefs.org'
license           'Apache-2.0'
description       'Installs and configures mongodb'
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
source_url        'https://github.com/sous-chefs/mongodb' if respond_to?(:source_url)
issues_url        'https://github.com/sous-chefs/mongodb/issues' if respond_to?(:issues_url)
chef_version      '>= 13.0'
version           '2.0.0'

depends 'build-essential', '>= 5.0.0'

supports 'amazon'
supports 'centos'
supports 'debian'
supports 'oracle'
supports 'redhat'
supports 'ubuntu'
