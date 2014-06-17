require 'spec_helper'

describe Puppet::Type.type(:nexus_connection_settings).provider(:ruby) do
  describe :map_config_to_resource_hash do
    let(:resource_hash) do
      described_class::map_config_to_resource_hash(global_config)
    end

    describe 'minimal example' do
      let(:global_config) do
        {
          'globalConnectionSettings' => {
            'connectionTimeout'   => 10,
            'retrievalRetryCount' => 3
          }
        }
      end

      specify { expect(resource_hash[:timeout]).to eq(10) }
      specify { expect(resource_hash[:retries]).to eq(3) }
      specify { expect(resource_hash[:query_string]).to eq('') }
      specify { expect(resource_hash[:user_agent_fragment]).to eq('') }
    end

    describe 'complete example' do
      let(:global_config) do
        {
          'globalConnectionSettings' => {
            'connectionTimeout'   => 200,
            'retrievalRetryCount' => 0,
            'queryString'         => 'foo=bar',
            'userAgentString'     => 'foobar'
          }
        }
      end

      specify { expect(resource_hash[:timeout]).to eq(200) }
      specify { expect(resource_hash[:retries]).to eq(0) }
      specify { expect(resource_hash[:query_string]).to eq('foo=bar') }
      specify { expect(resource_hash[:user_agent_fragment]).to eq('foobar') }
    end

    describe 'decodes HTML entities in queryString' do
      let(:global_config) do
        {
          'globalConnectionSettings' => {
            'connectionTimeout'   => 10,
            'retrievalRetryCount' => 3,
            'queryString'         => 'foo=bar&amp;foo2=bar2'
          }
        }
      end

      specify { expect(resource_hash[:query_string]).to eq('foo=bar&foo2=bar2') }
    end
  end

  describe :map_resource_to_config do
    let(:resource) do
      {
        :timeout             => 100,
        :retries             => 3,
        :query_string        => '',
        :user_agent_fragment => ''
      }
    end

    let(:instance) do
      instance = described_class.new()
      instance.resource = resource
      instance
    end

    specify 'should return all changes within globalConnectionSettings hash' do
      expect(instance.map_resource_to_config.keys).to eq(['globalConnectionSettings'])
    end

    specify 'should map timeout to connectionTimeout' do
      resource[:timeout] = 100
      expect(instance.map_resource_to_config['globalConnectionSettings']).to include('connectionTimeout' => 100)
    end

    specify 'should map retries to retrievalRetryCount' do
      resource[:retries] = 3
      expect(instance.map_resource_to_config['globalConnectionSettings']).to include('retrievalRetryCount' => 3)
    end

    specify 'should map query_string to queryString' do
      resource[:query_string] = 'foo=bar'
      expect(instance.map_resource_to_config['globalConnectionSettings']).to include('queryString' => 'foo=bar')
    end

    specify 'should not encode HTML entities in query_string' do
      resource[:query_string] = 'foo=bar&foo2=bar2'
      expect(instance.map_resource_to_config['globalConnectionSettings']).to include('queryString' => 'foo=bar&foo2=bar2')
    end

    specify 'should omit empty query_string' do
      resource[:query_string] = ''
      expect(instance.map_resource_to_config['globalConnectionSettings']).not_to include('queryString')
    end

    specify 'should map user_agent_fragment to userAgentString' do
      resource[:user_agent_fragment] = 'foobar'
      expect(instance.map_resource_to_config['globalConnectionSettings']).to include('userAgentString' => 'foobar')
    end

    specify 'should omit empty user_agent_fragment' do
      resource[:user_agent_fragment] = ''
      expect(instance.map_resource_to_config['globalConnectionSettings']).not_to include('userAgentString')
    end
  end
end
