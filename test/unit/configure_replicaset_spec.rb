require 'rspec'
require_relative '../../libraries/mongodb'

describe 'configure_replicaset' do
  it 'should be true' do
    expect(true).to be true
  end
end

describe 'ReplicasetMember' do
  it 'should convert to hash' do
    raw = {
      'fqdn' => 'a.b.c',
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
end
