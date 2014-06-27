require 'rspec'
require_relative '../../libraries/replicaset_member'

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
