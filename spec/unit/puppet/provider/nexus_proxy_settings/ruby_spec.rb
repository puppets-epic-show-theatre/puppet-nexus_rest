require 'spec_helper'

describe Puppet::Type.type(:nexus_proxy_settings).provider(:ruby) do
  describe :map_config_to_resource_hash do
    let(:global_config) do
      {
        'remoteProxySettings' => {
          'httpProxySettings' => {
            'proxyHostname' => 'example.com',
            'proxyPort'     => 8080
          },
          'httpsProxySettings' => {
            'proxyHostname' => 'ssl.example.com',
            'proxyPort'     => 8443
          },
          'nonProxyHosts' => [
            'internal.example.com',
            '*.example.com'
          ]
        }
      }
    end

    let(:resource_hash) do
      described_class::map_config_to_resource_hash(global_config)
    end

    specify { expect(resource_hash[:http_proxy_enabled]).to eq(:true) }
    specify { expect(resource_hash[:http_proxy_hostname]).to eq('example.com') }
    specify { expect(resource_hash[:http_proxy_port]).to eq(8080) }
    specify { expect(resource_hash[:https_proxy_enabled]).to eq(:true) }
    specify { expect(resource_hash[:https_proxy_hostname]).to eq('ssl.example.com') }
    specify { expect(resource_hash[:https_proxy_port]).to eq(8443) }
    specify { expect(resource_hash[:non_proxy_hostnames]).to eq('internal.example.com,*.example.com') }
  end

  describe :map_resource_to_config do
    let(:resource) do
      {
        :http_proxy_enabled   => :true,
        :http_proxy_hostname  => 'example.com',
        :http_proxy_port      => 8080,
        :https_proxy_enabled  => :true,
        :https_proxy_hostname => 'ssl.example.com',
        :https_proxy_port     => 8443,
        :non_proxy_hostnames  => ''
      }
    end

    let(:instance) do
      instance = described_class.new()
      instance.resource = resource
      instance
    end

    specify 'should return all changes within remoteProxySettings hash' do
      expect(instance.map_resource_to_config.keys).to eq(['remoteProxySettings'])
    end

    specify 'should add httpProxySettings hash if HTTP proxy is enabled' do
      resource[:http_proxy_enabled] = :true
      expect(instance.map_resource_to_config['remoteProxySettings']).to include('httpProxySettings')
    end

    specify 'should omit httpProxySettings hash if HTTP proxy is disabled' do
      resource[:http_proxy_enabled] = :false
      expect(instance.map_resource_to_config['remoteProxySettings']).not_to include('httpProxySettings')
    end

    specify 'should map http_proxy_hostname to proxyHostname in httpProxySettings hash' do
      resource[:http_proxy_hostname] = 'example.com'
      expect(instance.map_resource_to_config['remoteProxySettings']['httpProxySettings']).to include('proxyHostname' => 'example.com')
    end

    specify 'should map http_proxy_port to proxyPort in httpProxySettings hash' do
      resource[:http_proxy_port] = 8080
      expect(instance.map_resource_to_config['remoteProxySettings']['httpProxySettings']).to include('proxyPort' => 8080)
    end

    specify 'should add httpsProxySettings hash if HTTPS proxy is enabled' do
      resource[:https_proxy_enabled] = :true
      expect(instance.map_resource_to_config['remoteProxySettings']).to include('httpsProxySettings')
    end

    specify 'should omit httpsProxySettings hash if HTTPS proxy is disabled' do
      resource[:https_proxy_enabled] = :false
      expect(instance.map_resource_to_config['remoteProxySettings']).not_to include('httpsProxySettings')
    end

    specify 'should map https_proxy_hostname to proxyHostname in httpProxySettings hash' do
      resource[:https_proxy_hostname] = 'ssl.example.com'
      expect(instance.map_resource_to_config['remoteProxySettings']['httpsProxySettings']).to include('proxyHostname' => 'ssl.example.com')
    end

    specify 'should map https_proxy_port to proxyPort in httpProxySettings hash' do
      resource[:https_proxy_port] = 8443
      expect(instance.map_resource_to_config['remoteProxySettings']['httpsProxySettings']).to include('proxyPort' => 8443)
    end

    specify 'should map non_proxy_hostnames to an array' do
      resource[:non_proxy_hostnames] = 'internal.example.com,*.example.com'
      expect(instance.map_resource_to_config['remoteProxySettings']).to include('nonProxyHosts' => ['internal.example.com', '*.example.com'])
    end
  end
end
