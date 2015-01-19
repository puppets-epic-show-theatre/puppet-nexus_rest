require 'puppet_x/nexus/util'
require 'spec_helper'

describe Nexus::Util do

  contrived_original = {
    'a' => [],
    'b' => {
      'b.a' => {
        'b.a.a' => 1,
        'b.a.b' => {
          'b.a.b.a' => [],
          'b.a.b.b' => nil
        },
        'b.b' => {
          'b.b.a' => 2,
          'b.b.b' => {},
          'b.b.c' => [3]
        }
      },
    },
    'c' => 1,
    'd' => nil,
  }

  contrived_stripped = {
    'b' => {
      'b.a' => {
        'b.a.a' => 1,
        'b.b' => {
          'b.b.a' => 2,
          'b.b.c' => [3]
        }
      }
    },
    'c' => 1
  }

  concrete_original = {
    'id'                            => 'some-id',
    'name'                          => 'some-name',
    'writePolicy'                   => 'some-policy',
    'metadataMaxAge'                => 'some-value',
    'remoteStorage'                 => {
      'remoteStorageUrl'            =>  'some-url',
      'connectionSettings'          => {
        'connectionTimeout'         => nil,
        'retrievalRetryCount'       => nil,
        'queryString'               => nil,
        'userAgentString'           => nil
      },
      'authentication'              => {
        'username'                  => nil,
        'password'                  => nil,
        'ntlmHost'                  => nil,
        'ntlmDomain'                => nil,
      }
    }
  }

  concrete_stripped = {
    'id'                            => 'some-id',
    'name'                          => 'some-name',
    'writePolicy'                   => 'some-policy',
    'metadataMaxAge'                => 'some-value',
    'remoteStorage'                 => {
      'remoteStorageUrl'            =>  'some-url'
    }
  }

  describe :strip_hash_contrived do
    specify { expect(described_class.strip_hash(contrived_original)).to eq(contrived_stripped) }
  end

  describe :strip_hash_concrete do
    specify { expect(described_class.strip_hash(concrete_original)).to eq(concrete_stripped) }
  end

  describe :a_boolean_or_default do
    specify { expect(described_class.a_boolean_or_default(true, :default)).to eq(:true) }
    specify { expect(described_class.a_boolean_or_default(false, :default)).to eq(:false) }
    specify { expect(described_class.a_boolean_or_default(nil, :default)).to eq(:default) }
  end

  describe :a_list_or_default do
    specify { expect(described_class.a_list_or_default(['a', 'b'], :default)).to eq('a,b') }
    specify { expect(described_class.a_list_or_default(['a'], :default)).to eq('a') }
    specify { expect(described_class.a_list_or_default([], :default)).to eq('') }
    specify { expect(described_class.a_list_or_default(nil, :default)).to eq(:default) }
  end
end
