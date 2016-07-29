require 'spec_helper'

describe Puppet::Type.type(:nexus_crowd_settings).provider(:ruby) do
  describe :map_config_to_resource_hash do
    let(:minimal_config_template) do
      {
        'applicationName' => 'username',
        'crowdServerUrl'  => 'http://crowd-server.com'
      }
    end

    let(:resource_hash) do
      described_class::map_config_to_resource_hash(crowd_settings)
    end

    describe 'complete example'  do
      let(:crowd_settings) do
        minimal_config_template['httpTimeout'] = 60
        minimal_config_template
      end

      specify { expect(resource_hash[:application_name]).to eq('username') }
      specify { expect(resource_hash[:crowd_server_url]).to eq('http://crowd-server.com') }
      specify { expect(resource_hash[:http_timeout]).to eq(60) }
    end

    describe 'minimal example'  do
      let(:crowd_settings) { minimal_config_template }

      specify { expect(resource_hash[:application_name]).to eq('username') }
      specify { expect(resource_hash[:crowd_server_url]).to eq('http://crowd-server.com') }
      specify { expect(resource_hash[:http_timeout]).to eq(nil) }
    end

    describe 'with application_password set' do
      let(:crowd_settings) do
        minimal_config_template['applicationPassword'] = '|$|N|E|X|U|S|$|'
        minimal_config_template
      end

      specify { expect(resource_hash[:application_password]).to eq(:present)}
    end
  end

  describe '#map_resource_hash_to_config' do
    let(:resource) do
      {
        :application_name           => 'username',
        :crowd_server_url           => 'http://crowd-server.com',
        :http_timeout               => 60
      }
    end

    let(:instance) do
      instance = described_class.new()
      instance.resource = resource
      instance
    end

    specify 'with password set' do
      resource[:application_password_value] = 'password'
      resource[:application_password]       =  :present
      crowd_settings = instance.map_resource_hash_to_config
      expect(crowd_settings['data']['applicationName']).to eq('username')
      expect(crowd_settings['data']['applicationPassword']).to eq('password')
      expect(crowd_settings['data']['crowdServerUrl']).to eq('http://crowd-server.com')
      expect(crowd_settings['data']['httpTimeout']).to eq(60)
    end
  end
end