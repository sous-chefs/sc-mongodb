require 'rspec'
require_relative '../../libraries/replicaset_config'

describe 'ReplicasetConfig' do
  let(:member) do
    Chef::ResourceDefinitionList::MongoDB::ReplicasetMember.new(
      { 'fqdn' => 'a.b.c',
        'ipaddress' => '1.2.3.4',
        'mongodb' => {
          'config' => {
            'port' => 27_017,
          },
          'replica_arbiter_only' => 'true',
          'replica_slave_delay' => 5,
          'replica_tags' => {},
          'replica_votes' => 1,
          'replica_build_indexes' => true,
          'replica_hidden' => true,
        },
      },
      0
    )
  end

  let(:config) do
    config = Chef::ResourceDefinitionList::MongoDB::ReplicasetConfig.new 'rs_test'
    config << member
    config
  end

  it '#id' do
    expect(config.id).to eq('rs_test')
  end

  it '#<<' do
    expect(config.members[member.host]).to eq(member)
  end

  it '#to_config' do
    expected = {
      '_id' =>      'rs_test',
      'members' =>  [{
        '_id' =>           0,
        'host' =>          'a.b.c:27017',
        'arbiterOnly' =>   true,
        'buildIndexes' =>  true,
        'hidden' =>        true,
        'slaveDelay' =>    5,
        'priority' =>      0,
        'tags' =>          {},
        'votes' =>         1,
      }],
      'version' => 1
    }
    expect(config.to_config).to eq(expected)
  end

  it '#member_list' do
    expected = [{
      '_id' =>           0,
      'host' =>          'a.b.c:27017',
      'arbiterOnly' =>   true,
      'buildIndexes' =>  true,
      'hidden' =>        true,
      'slaveDelay' =>    5,
      'priority' =>      0,
      'tags' =>          {},
      'votes' =>         1,
    }]
    expect(config.member_list).to eq(expected)
  end

  it '#matches?' do
    other = {
      '_id' =>      'rs_test',
      'members' =>  [{
        '_id' =>           0,
        'host' =>          'a.b.c:27017',
        'arbiterOnly' =>   true,
        'buildIndexes' =>  true,
        'hidden' =>        true,
        'slaveDelay' =>    5,
        'priority' =>      0,
        'tags' =>          {},
        'votes' =>         1,
      }]
    }
    expect(config.matches? other).to eq(true)
  end

  it '#matches_by_ipaddress?' do
    other = {
      '_id' =>      'rs_test',
      'members' =>  [{
        '_id' =>           0,
        'host' =>          '1.2.3.4:27017',
      }]
    }
    expect(config.matches_by_ipaddress? other).to eq(true)
  end

  it '#inspect' do
    expected = '<ReplicasetConfig id="rs_test" members="a.b.c:27017" version=1>'
    expect(config.inspect).to eq(expected)
  end
end
