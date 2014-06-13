require 'spec_helper'

describe Puppet::Type.type(:nexus_application_server_settings).provider(:ruby) do
  describe :map_config_to_resource_hash do
    let(:global_config) do
      {
        'globalRestApiSettings' => {
          'forceBaseUrl' => false,
          'baseUrl'      => 'https://example.com',
          'uiTimeout'    => 60
        }
      }
    end

    let(:resource_hash) do
      described_class::map_config_to_resource_hash(global_config)
    end

    specify { expect(resource_hash[:forceurl]).to eq(:false) }
    specify { expect(resource_hash[:baseurl]).to eq('https://example.com') }
    specify { expect(resource_hash[:timeout]).to eq(60) }
  end

  describe :map_resource_to_config do
    let(:resource) do
      {
        :forceurl => :false,
        :baseurl  => 'https://example.com',
        :timeout  => 60
      }
    end

    let(:instance) do
      instance = described_class.new()
      instance.resource = resource
      instance
    end

    specify 'should return all changes within globalRestApiSettings hash' do
      expect(instance.map_resource_to_config.keys).to eq(['globalRestApiSettings'])
    end

    specify 'should map forceurl :true to true' do
      resource[:forceurl] = :true
      expect(instance.map_resource_to_config['globalRestApiSettings']).to include('forceBaseUrl' => true)
    end

    specify 'should map forceurl :false to false' do
      expect(instance.map_resource_to_config['globalRestApiSettings']).to include('forceBaseUrl' => false)
    end

    specify 'should map baseurl' do
      expect(instance.map_resource_to_config['globalRestApiSettings']).to include('baseUrl' => 'https://example.com')
    end

    specify 'should map timeout' do
      expect(instance.map_resource_to_config['globalRestApiSettings']).to include('uiTimeout' => 60)
    end
  end
end
