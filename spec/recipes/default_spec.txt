require 'spec_helper'

describe 'sc-mongodb::default' do
  context 'with default node attributes' do
    # mongod_conf_XXXX: the variables are a copy of what is in the default
    # attributes file so that the OS's can be tested for correct attribute
    # assignments
    let(:mongod_conf_rhel) do
      {
        'net' => {
          'port' => 27017,
          'bindIp' => '0.0.0.0',
        },
        'systemLog' => {
          'destination' => 'file',
          'logAppend' => true,
          'path' => '/var/log/mongodb/mongod.log',
        },
        'processManagement' => {
          'fork' => true,
          'pidFilePath' => '/var/run/mongodb/mongod.pid',
        },
        'storage' => {
          'journal' => {
            'enabled' => true,
          },
          'dbPath' => '/var/lib/mongo',
          'engine' => 'wiredTiger',
        },
        'replication' => {
          'oplogSizeMB' => nil,
          'replSetName' => nil,
          'secondaryIndexPrefetch' => nil,
          'enableMajorityReadConcern' => nil,
        },
        'security' => {
          'keyFile' => nil,
        },
      }
    end

    let(:mongod_conf_debian) do
      {
        'net' => {
          'port' => 27017,
          'bindIp' => '0.0.0.0',
        },
        'systemLog' => {
          'destination' => 'file',
          'logAppend' => true,
          'path' => '/var/log/mongodb/mongod.log',
        },
        'storage' => {
          'journal' => {
            'enabled' => true,
          },
          'dbPath' => '/var/lib/mongodb',
          'engine' => 'wiredTiger',
        },
        'replication' => {
          'oplogSizeMB' => nil,
          'replSetName' => nil,
          'secondaryIndexPrefetch' => nil,
          'enableMajorityReadConcern' => nil,
        },
        'security' => {
          'keyFile' => nil,
        },
      }
    end

    # mongod_init: Cookbook supports 2 different init systems right now
    let(:mongod_init_sysvinit) do
      '/etc/init.d/mongod'
    end

    let(:mongod_init_upstart) do
      '/etc/init/mongod.conf'
    end

    # mongod_packager_options: pkg install options for mongo per OS
    let(:mongod_packager_options_rhel) do
      '--nogpgcheck'
    end

    let(:mongod_packager_options_debian) do
      '-o Dpkg::Options::="--force-confold" --force-yes'
    end

    # mongod_sysconfig_file: sysconfig file location for mongo per OS
    let(:mongod_sysconfig_file_debian) do
      '/etc/default/mongodb'
    end

    let(:mongod_sysconfig_file_rhel) do
      '/etc/sysconfig/mongodb'
    end

    # mongod_version: RHEL appends a release and OS versions to their versions
    let(:mongod_version_rhel) do
      '3.2.18-1.el7'
    end

    let(:mongod_version_debian) do
      '3.2.18'
    end

    # All tests in this section run for all OS's
    shared_examples_for 'default recipe' do
      it 'should include "sc-mongodb::install" recipe' do
        expect_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('sc-mongodb::install')
        chef_run
      end

      it 'should install "build-tools" build_essential' do
        expect(chef_run).to install_build_essential('build-tools')
      end

      it 'should create sysconfig install template' do
        expect(chef_run).to create_file_if_missing("#{mongod_sysconfig_file} install").with(
          path: mongod_sysconfig_file,
          content: 'ENABLE_MONGODB=no',
          owner: 'root',
          group: 'root',
          mode: '0644'
        )
      end

      it 'should create "/etc/mongod.conf install" template' do
        expect(chef_run).to create_template_if_missing('/etc/mongod.conf install').with(
          path: '/etc/mongod.conf',
          cookbook: 'sc-mongodb',
          source: 'mongodb.conf.erb',
          owner: 'root',
          group: 'root',
          mode: '0644',
          variables: {
            config: mongod_conf,
          }
        )
      end

      it 'should not run "mongodb-systemctl-daemon-reload-mongod" execute' do
        expect(chef_run).to_not run_execute('mongodb-systemctl-daemon-reload-mongod')
      end

      it 'should create init install template' do
        mode = mongod_init_source == 'debian-mongodb.upstart.erb' ? '0644' : '0755'
        expect(chef_run).to create_template_if_missing("#{mongod_init_file} install").with(
          path: mongod_init_file,
          cookbook: 'sc-mongodb',
          source: mongod_init_source,
          owner: 'root',
          group: 'root',
          mode: mode,
          variables: {
            provides: 'mongod',
            dbconfig_file: '/etc/mongod.conf',
            sysconfig_file: mongod_sysconfig_file,
            ulimit: {
              'fsize' => 'unlimited',
              'cpu' => 'unlimited',
              'as' => 'unlimited',
              'nofile' => 64000,
              'rss' => 'unlimited',
              'nproc' => 32000,
            },
            bind_ip: '0.0.0.0',
            port: 27017,
          }
        )
      end

      it 'should install "mongodb-org" package' do
        expect(chef_run).to install_package('mongodb-org').with(
          options: mongod_packager_options,
          version: mongod_version
        )
      end

      it 'should create sysconfig template' do
        expect(chef_run).to create_template(mongod_sysconfig_file).with(
          path: mongod_sysconfig_file,
          cookbook: 'sc-mongodb',
          source: 'mongodb.sysconfig.erb',
          owner: 'root',
          group: 'root',
          mode: '0644',
          variables: {
            sysconfig: {
              'DAEMON' => '/usr/bin/$NAME',
              'DAEMON_USER' => file_owner,
              'DAEMON_OPTS' => '--config /etc/mongod.conf',
              'CONFIGFILE' => '/etc/mongod.conf',
              'ENABLE_MONGODB' => 'yes',
            },
          }
        )
      end

      it 'should create "/etc/mongod.conf" template' do
        expect(chef_run).to create_template('/etc/mongod.conf').with(
          path: '/etc/mongod.conf',
          cookbook: 'sc-mongodb',
          source: 'mongodb.conf.erb',
          owner: 'root',
          group: 'root',
          mode: '0644',
          variables: {
            config: mongod_conf,
          }
        )
      end

      it 'should create "/var/log/mongodb" directory' do
        expect(chef_run).to create_directory('/var/log/mongodb').with(
          owner: file_owner,
          group: file_owner,
          mode: '0755'
        )
      end

      it 'should create dbPath directory' do
        expect(chef_run).to create_directory(mongod_conf['storage']['dbPath']).with(
          owner: file_owner,
          group: file_owner,
          mode: '0755'
        )
      end

      it 'should not run "mongodb-systemctl-daemon-reload" execute' do
        expect(chef_run).to_not run_execute('mongodb-systemctl-daemon-reload')
      end

      it 'should create init template' do
        mode = mongod_init_source == 'debian-mongodb.upstart.erb' ? '0644' : '0755'
        expect(chef_run).to create_template(mongod_init_file).with(
          path: mongod_init_file,
          cookbook: 'sc-mongodb',
          source: mongod_init_source,
          owner: 'root',
          group: 'root',
          mode: mode,
          variables: {
            provides: 'mongod',
            dbconfig_file: '/etc/mongod.conf',
            sysconfig_file: mongod_sysconfig_file,
            ulimit: {
              'fsize' => 'unlimited',
              'cpu' => 'unlimited',
              'as' => 'unlimited',
              'nofile' => 64000,
              'rss' => 'unlimited',
              'nproc' => 32000,
            },
            bind_ip: '0.0.0.0',
            port: 27017,
          }
        )
      end

      it 'should enable "mongod" service' do
        expect(chef_run).to enable_service('mongod')
      end

      it 'should start "mongod" service' do
        expect(chef_run).to start_service('mongod')
      end
    end

    shared_examples_for 'debian based install' do
      it 'should install "mongodb-org-server" package' do
        expect(chef_run).to install_package('mongodb-org-server').with(
          options: mongod_packager_options,
          version: mongod_version
        )
      end

      it 'should install "mongodb-org-shell" package' do
        expect(chef_run).to install_package('mongodb-org-shell').with(
          options: mongod_packager_options,
          version: mongod_version
        )
      end

      it 'should install "mongodb-org-tools" package' do
        expect(chef_run).to install_package('mongodb-org-tools').with(
          options: mongod_packager_options,
          version: mongod_version
        )
      end

      it 'should install "mongodb-org-mongos" package' do
        expect(chef_run).to install_package('mongodb-org-mongos').with(
          options: mongod_packager_options,
          version: mongod_version
        )
      end
    end

    context 'CentOS' do
      let(:chef_run) { ChefSpec::SoloRunner.new(platform: 'centos', version: '7.3.1611').converge(described_recipe) }

      it_behaves_like 'default recipe' do
        let(:file_owner) { 'mongod' }
        let(:mongod_conf) { mongod_conf_rhel }
        let(:mongod_init_file) { mongod_init_sysvinit }
        let(:mongod_init_source) { 'redhat-mongodb.init.erb' }
        let(:mongod_packager_options) { mongod_packager_options_rhel }
        let(:mongod_sysconfig_file) { mongod_sysconfig_file_rhel }
        let(:mongod_version) { mongod_version_rhel }
      end

      it 'should create "mongodb" yum_repository' do
        expect(chef_run).to create_yum_repository('mongodb').with(
          description: 'mongodb RPM Repository',
          baseurl: 'https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/3.2/x86_64',
          gpgkey: 'https://www.mongodb.org/static/pgp/server-3.2.asc',
          gpgcheck: true,
          sslverify: true,
          enabled: true
        )
      end
    end

    context 'Debian 7' do
      let(:chef_run) { ChefSpec::SoloRunner.new(platform: 'debian', version: '7.11').converge(described_recipe) }

      it_behaves_like 'default recipe' do
        let(:file_owner) { 'mongodb' }
        let(:mongod_conf) { mongod_conf_debian }
        let(:mongod_init_file) { mongod_init_sysvinit }
        let(:mongod_init_source) { 'debian-mongodb.init.erb' }
        let(:mongod_packager_options) { mongod_packager_options_debian }
        let(:mongod_sysconfig_file) { mongod_sysconfig_file_debian }
        let(:mongod_version) { mongod_version_debian }
      end

      it_behaves_like 'debian based install' do
        let(:mongod_packager_options) { mongod_packager_options_debian }
        let(:mongod_version) { mongod_version_debian }
      end

      it 'should create "mongodb" yum_repository' do
        expect(chef_run).to add_apt_repository('mongodb').with(
          uri: 'http://repo.mongodb.org/apt/debian',
          distribution: 'wheezy/mongodb-org/3.2',
          components: ['main'],
          key: ['https://www.mongodb.org/static/pgp/server-3.2.asc']
        )
      end
    end

    context 'Debian 8' do
      let(:chef_run) { ChefSpec::SoloRunner.new(platform: 'debian', version: '9.4').converge(described_recipe) }

      it_behaves_like 'default recipe' do
        let(:file_owner) { 'mongodb' }
        let(:mongod_conf) { mongod_conf_debian }
        let(:mongod_init_file) { mongod_init_sysvinit }
        let(:mongod_init_source) { 'debian-mongodb.init.erb' }
        let(:mongod_packager_options) { mongod_packager_options_debian }
        let(:mongod_sysconfig_file) { mongod_sysconfig_file_debian }
        let(:mongod_version) { mongod_version_debian }
      end

      it_behaves_like 'debian based install' do
        let(:mongod_packager_options) { mongod_packager_options_debian }
        let(:mongod_version) { mongod_version_debian }
      end

      it 'should create "mongodb" yum_repository' do
        expect(chef_run).to add_apt_repository('mongodb').with(
          uri: 'http://repo.mongodb.org/apt/debian',
          distribution: 'jessie/mongodb-org/3.2',
          components: ['main'],
          key: ['https://www.mongodb.org/static/pgp/server-3.2.asc']
        )
      end
    end

    context 'Ubuntu 16.04' do
      let(:chef_run) { ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '16.04').converge(described_recipe) }

      it_behaves_like 'default recipe' do
        let(:file_owner) { 'mongodb' }
        let(:mongod_conf) { mongod_conf_debian }
        let(:mongod_init_file) { mongod_init_sysvinit }
        let(:mongod_init_source) { 'debian-mongodb.init.erb' }
        let(:mongod_packager_options) { mongod_packager_options_debian }
        let(:mongod_sysconfig_file) { mongod_sysconfig_file_debian }
        let(:mongod_version) { mongod_version_debian }
      end

      it_behaves_like 'debian based install' do
        let(:mongod_packager_options) { mongod_packager_options_debian }
        let(:mongod_version) { mongod_version_debian }
      end

      it 'should create "mongodb" yum_repository' do
        expect(chef_run).to add_apt_repository('mongodb').with(
          uri: 'http://repo.mongodb.org/apt/ubuntu',
          distribution: 'xenial/mongodb-org/3.2',
          components: ['multiverse'],
          key: ['https://www.mongodb.org/static/pgp/server-3.2.asc']
        )
      end
    end
  end
end
