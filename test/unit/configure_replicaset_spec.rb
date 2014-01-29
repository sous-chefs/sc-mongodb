require 'rspec'
require_relative '../../libraries/mongodb'

describe 'configure_replicaset' do
  it 'should be true' do
    expect(true).to be true
  end
end

describe 'ReplicasetMember' do
  let(:raw) do
    {
      'fqdn' => 'a.b.c',
      'ipaddress' => '1.2.3.4',
      'mongodb' => {
        'config' => {
          'port' => 27_017
        },
        'replica_arbiter_only' => 'true',
        'replica_slave_delay' => 5,
        'replica_tags' => {},
        'replica_votes' => 1,
        'replica_build_indexes' => true,
        'replica_hidden' => true
      }
    }
  end
  it 'should convert to hash' do
    member = Chef::ResourceDefinitionList::MongoDB::ReplicasetMember.new raw
    expected = {
      'host' => 'a.b.c:27017',
      'arbiterOnly' => true,
      'buildIndexes' => true,
      'hidden' => true,
      'slaveDelay' => 5,
      'priority' => 0,
      'tags' => {},
      'votes' => 1
    }
    expect(member.to_h).to eq(expected)
  end
  it 'should convert to hash with id when given' do
    member = Chef::ResourceDefinitionList::MongoDB::ReplicasetMember.new raw, 5
    expected = {
      'host' => 'a.b.c:27017',
      'arbiterOnly' => true,
      'buildIndexes' => true,
      'hidden' => true,
      'slaveDelay' => 5,
      'priority' => 0,
      'tags' => {},
      'votes' => 1,
      '_id' => 5,
    }
    expect(member.to_h).to eq(expected)
  end
  it 'should convert to hash with id when given' do
    member = Chef::ResourceDefinitionList::MongoDB::ReplicasetMember.new raw, 5
    expected = {
      'host' => '1.2.3.4:27017',
      '_id' => 5,
    }
    expect(member.to_h_with_ipaddress).to eq(expected)
  end
end

describe 'ReplicasetConfig' do
  let(:member) do
    Chef::ResourceDefinitionList::MongoDB::ReplicasetMember.new(
      { 'fqdn' => 'a.b.c',
        'ipaddress' => '1.2.3.4',
        'mongodb' => {
          'port' => 27_017,
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

  it '#name' do
    expect(config.name).to eq('rs_test')
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
      }]
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
    expected = '<ReplicasetConfig name="rs_test" members="a.b.c:27017">'
    expect(config.inspect).to eq(expected)
  end

end
