#
# Copyright 2014, Joseph Holsten
# Authors:
#       Joseph Anthony Pasquale Holsten <joseph@josephholsten.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'json'

# helper to cast any object to a boolean
def Boolean(obj) # rubocop:disable MethodName
  obj ? true : false
end

# ensure parents exist
class Chef
  class ResourceDefinitionList
  end
end

class Chef::ResourceDefinitionList::MongoDB
  # ReplicasetMember is a support class to convert a node object into a
  # MongoDB replicaset member document.
  #
  # This implementation maps document keys onto values from the node
  # object, and requires each to exist:
  #
  #    host:          "{node.fqdn}:{node.mongodb.config.port}"
  #    arbiterOnly:   node.mongodb.replica_arbiter_only
  #    buildIndexes:  node.mongodb.replica_build_indexes
  #    hidden:        node.mongodb.replica_hidden
  #    slaveDelay:    node.mongodb.replica_slave_delay
  #    priority:      node.mongodb.replica_priority
  #    tags:          node.mongodb.replica_tags
  #    votes:         node.mongodb.replica_votes
  #
  # Originally this would not send entries if they matched the defaults:
  #
  #    arbiterOnly:   false
  #    buildIndexes:  true
  #    hidden:        false
  #    slaveDelay:    0
  #    priority:      1
  #    tags:          {}
  #    votes:         1
  class ReplicasetMember
    attr_accessor :node, :id

    def initialize(node, id = nil)
      @node = node
      @id = id
    end

    def fqdn
      node['fqdn']
    end

    def mongodb_port
      mongodb['config']['port']
    end

    def fqdn_host
      "#{fqdn}:#{mongodb_port}"
    end

    def ipaddress_host
      "#{ipaddress}:#{mongodb_port}"
    end

    def host
      fqdn_host
    end

    def arbiter_only?
      Boolean(mongodb['replica_arbiter_only'])
    end

    def build_indexes?
      Boolean(mongodb['replica_build_indexes'])
    end

    def hidden?
      Boolean(mongodb['replica_hidden'])
    end

    def slave_delay
      Integer(mongodb['replica_slave_delay'])
    end

    # priority must be 0 if the member lacks buildIndexes, is hidden or
    # has slaveDelay
    def priority
      if !build_indexes? || hidden? || slave_delay?
        # must not become primary
        priority = 0
      else
        priority = mongodb['replica_priority']
      end
      priority
    end

    def ipaddress
      node['ipaddress']
    end

    def tags
      mongodb['replica_tags'].to_hash
    end

    def votes
      Integer(mongodb['replica_votes'])
    end

    def to_h
      hash = {
        'host' =>          host,
        'arbiterOnly' =>   arbiter_only?,
        'buildIndexes' =>  build_indexes?,
        'hidden' =>        hidden?,
        'slaveDelay' =>    slave_delay,
        'priority' =>      priority,
        'tags' =>          tags,
        'votes' =>         votes
      }
      hash['_id'] = id if id
      hash
    end

    def to_h_with_ipaddress
      hash = {
        'host' =>          ipaddress_host
      }
      hash['_id'] = id if id
      hash
    end

    def <=>(other)
      if other.respond_to :host
        host <=> other.host
      else
        nil
      end
    end

    private

    def mongodb
      node['mongodb']
    end
  end
end
