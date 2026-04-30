# frozen_string_literal: true

require 'spec_helper'

describe 'mongodb_repository' do
  step_into :mongodb_repository

  context 'on Ubuntu 24.04' do
    platform 'ubuntu', '24.04'

    recipe do
      mongodb_repository 'mongodb' do
        version '8.0.5'
      end
    end

    it 'configures the MongoDB apt repository' do
      expect(chef_run).to add_apt_repository('mongodb').with(
        uri: 'https://repo.mongodb.org/apt/ubuntu',
        distribution: 'noble/mongodb-org/8.0',
        components: ['multiverse'],
        key: ['https://pgp.mongodb.com/server-8.0.asc']
      )
    end
  end

  context 'on Debian 12' do
    platform 'debian', '12'

    recipe do
      mongodb_repository 'mongodb'
    end

    it 'configures the MongoDB apt repository' do
      expect(chef_run).to add_apt_repository('mongodb').with(
        uri: 'https://repo.mongodb.org/apt/debian',
        distribution: 'bookworm/mongodb-org/8.0',
        components: ['main'],
        key: ['https://pgp.mongodb.com/server-8.0.asc']
      )
    end
  end

  context 'on Rocky Linux 9' do
    platform 'rocky', '9'

    recipe do
      mongodb_repository 'mongodb'
    end

    it 'configures the MongoDB yum repository' do
      expect(chef_run).to create_yum_repository('mongodb').with(
        description: 'MongoDB RPM Repository',
        baseurl: 'https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/8.0/$basearch/',
        gpgkey: 'https://pgp.mongodb.com/server-8.0.asc',
        gpgcheck: true,
        sslverify: true,
        enabled: true
      )
    end
  end

  context 'on Amazon Linux 2023' do
    platform 'amazon', '2023'

    recipe do
      mongodb_repository 'mongodb'
    end

    it 'configures the MongoDB yum repository' do
      expect(chef_run).to create_yum_repository('mongodb').with(
        baseurl: 'https://repo.mongodb.org/yum/amazon/2023/mongodb-org/8.0/$basearch/',
        gpgkey: 'https://pgp.mongodb.com/server-8.0.asc'
      )
    end
  end
end
