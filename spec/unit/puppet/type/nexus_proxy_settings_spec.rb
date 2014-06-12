require 'spec_helper'

describe Puppet::Type.type(:nexus_proxy_settings) do
  before :each do
    @provider_class = described_class.provide(:simple) do
      mk_resource_methods
      def flush; end
      def self.instances; []; end
    end
    described_class.stubs(:defaultprovider).returns @provider_class
  end

  let(:valid_hostname) { 'example.com' }
  let(:valid_port) { 8080 }
  let(:configured_http_proxy) do
    {
      :name                => 'any',
      :http_proxy_enabled  => :true,
      :http_proxy_hostname => valid_hostname,
      :http_proxy_port     => valid_port
    }
  end

  describe :http_proxy_enabled do
    specify 'should accept :true' do
      expect { described_class.new(:name => 'any', :http_proxy_enabled => :true, :http_proxy_hostname => valid_hostname, :http_proxy_port => valid_port) }.to_not raise_error
    end

    specify 'should accept :false and not require http_proxy_hostname or http_proxy_port' do
      expect { described_class.new(:name => 'any', :http_proxy_enabled => :false) }.to_not raise_error
    end

    specify 'should require http_proxy_hostname when set to :true' do
      expect {
        described_class.new(:name => 'any', :http_proxy_enabled => :true, :http_proxy_port => valid_port)
      }.to raise_error(Puppet::ResourceError, /http_proxy_hostname is required/)
    end

    specify 'should require http_proxy_port when set to :true' do
      expect {
        described_class.new(:name => 'any', :http_proxy_enabled => :true, :http_proxy_hostname => valid_hostname)
      }.to raise_error(Puppet::ResourceError, /http_proxy_port is required/)
    end
  end

  describe :http_proxy_hostname do
    specify 'should accept a valid hostname' do
      expect { described_class.new(:name => 'any', :http_proxy_enabled => :true, :http_proxy_hostname => valid_hostname, :http_proxy_port => valid_port) }.to_not raise_error
    end

    specify 'should accept a localhost' do
      expect { described_class.new(:name => 'any', :http_proxy_enabled => :true, :http_proxy_hostname => 'localhost', :http_proxy_port => valid_port) }.to_not raise_error
    end

    specify 'should not accept empty string' do
      expect {
        described_class.new(:name => 'any', :http_proxy_enabled => :true, :http_proxy_hostname => '', :http_proxy_port => valid_port)
      }.to raise_error(Puppet::ResourceError, /Parameter http_proxy_hostname failed/)
    end
  end

  describe :http_proxy_port do
    specify 'should not accept empty string' do
      expect {
        described_class.new(:name => 'any', :http_proxy_enabled => :true, :http_proxy_hostname => valid_hostname, :http_proxy_port => '')
      }.to raise_error(Puppet::ResourceError, /Parameter http_proxy_port failed/)
    end

    specify 'should not accept characters' do
      expect {
        described_class.new(:name => 'any', :http_proxy_enabled => :true, :http_proxy_hostname => valid_hostname, :http_proxy_port => 'abc')
      }.to raise_error(Puppet::ResourceError, /Parameter http_proxy_port failed/)
    end

    specify 'should not accept port 0' do
      expect {
        described_class.new(:name => 'any', :http_proxy_enabled => :true, :http_proxy_hostname => valid_hostname, :http_proxy_port => 0)
      }.to raise_error(Puppet::ResourceError, /Parameter http_proxy_port failed/)
    end

    specify 'should accept port 1' do
      expect { described_class.new(:name => 'any', :http_proxy_enabled => :true, :http_proxy_hostname => valid_hostname, :http_proxy_port => 1) }.to_not raise_error
    end

    specify 'should accept port as string' do
      expect { described_class.new(:name => 'any', :http_proxy_enabled => :true, :http_proxy_hostname => valid_hostname, :http_proxy_port => '25') }.to_not raise_error
    end

    specify 'should accept port 65535' do
      expect { described_class.new(:name => 'any', :http_proxy_enabled => :true, :http_proxy_hostname => valid_hostname, :http_proxy_port => 65535) }.to_not raise_error
    end

    specify 'should not accept ports larger than 65535' do
      expect {
        described_class.new(:name => 'any', :http_proxy_enabled => :true, :http_proxy_hostname => valid_hostname, :http_proxy_port => 65536)
      }.to raise_error(Puppet::ResourceError, /Parameter http_proxy_port failed/)
    end
  end

  describe :https_proxy_enabled do
    specify 'should accept :true' do
      expect { described_class.new(configured_http_proxy.merge(:https_proxy_enabled => :true, :https_proxy_hostname => valid_hostname, :https_proxy_port => valid_port)) }.to_not raise_error
    end

    specify 'should accept :false and not require http_proxy_enabled' do
      expect { described_class.new(:name => 'any', :https_proxy_enabled => :false) }.to_not raise_error
    end

    specify 'should accept :false and not require https_proxy_hostname or https_proxy_port' do
      expect { described_class.new(configured_http_proxy.merge(:https_proxy_enabled => :false)) }.to_not raise_error
    end

    specify 'should require https_proxy_hostname when set to :true' do
      expect {
        described_class.new(configured_http_proxy.merge(:https_proxy_enabled => :true, :https_proxy_port => valid_port))
      }.to raise_error(Puppet::ResourceError, /https_proxy_hostname is required/)
    end

    specify 'should require https_proxy_port when set to :true' do
      expect {
        described_class.new(configured_http_proxy.merge(:https_proxy_enabled => :true, :https_proxy_hostname => valid_hostname))
      }.to raise_error(Puppet::ResourceError, /https_proxy_port is required/)
    end
  end

  describe :https_proxy_hostname do
    specify 'should accept a valid hostname' do
      expect { described_class.new(configured_http_proxy.merge(:https_proxy_enabled => :true, :https_proxy_hostname => valid_hostname, :https_proxy_port => valid_port)) }.to_not raise_error
    end

    specify 'should accept a localhost' do
      expect { described_class.new(configured_http_proxy.merge(:https_proxy_enabled => :true, :https_proxy_hostname => 'localhost', :https_proxy_port => valid_port)) }.to_not raise_error
    end

    specify 'should not accept empty string' do
      expect {
        described_class.new(configured_http_proxy.merge(:https_proxy_enabled => :true, :https_proxy_hostname => '', :https_proxy_port => valid_port))
      }.to raise_error(Puppet::ResourceError, /Parameter https_proxy_hostname failed/)
    end
  end

  describe :https_proxy_port do
    specify 'should not accept empty string' do
      expect {
        described_class.new(configured_http_proxy.merge(:https_proxy_enabled => :true, :https_proxy_hostname => valid_hostname, :https_proxy_port => ''))
      }.to raise_error(Puppet::ResourceError, /Parameter https_proxy_port failed/)
    end

    specify 'should not accept characters' do
      expect {
        described_class.new(configured_http_proxy.merge(:https_proxy_enabled => :true, :https_proxy_hostname => valid_hostname, :https_proxy_port => 'abc'))
      }.to raise_error(Puppet::ResourceError, /Parameter https_proxy_port failed/)
    end

    specify 'should not accept port 0' do
      expect {
        described_class.new(configured_http_proxy.merge(:https_proxy_enabled => :true, :https_proxy_hostname => valid_hostname, :https_proxy_port => 0))
      }.to raise_error(Puppet::ResourceError, /Parameter https_proxy_port failed/)
    end

    specify 'should accept port 1' do
      expect { described_class.new(configured_http_proxy.merge(:https_proxy_enabled => :true, :https_proxy_hostname => valid_hostname, :https_proxy_port => 1)) }.to_not raise_error
    end

    specify 'should accept port as string' do
      expect { described_class.new(configured_http_proxy.merge(:https_proxy_enabled => :true, :https_proxy_hostname => valid_hostname, :https_proxy_port => '25')) }.to_not raise_error
    end

    specify 'should accept port 65535' do
      expect { described_class.new(configured_http_proxy.merge(:https_proxy_enabled => :true, :https_proxy_hostname => valid_hostname, :https_proxy_port => 65535)) }.to_not raise_error
    end

    specify 'should not accept ports larger than 65535' do
      expect {
        described_class.new(configured_http_proxy.merge(:https_proxy_enabled => :true, :https_proxy_hostname => valid_hostname, :https_proxy_port => 65536))
      }.to raise_error(Puppet::ResourceError, /Parameter https_proxy_port failed/)
    end
  end

  describe :non_proxy_hostnames do
    specify 'should default to empty string' do
      expect(described_class.new(:name => 'any')[:non_proxy_hostnames]).to eq('')
    end

    specify 'should accept a single string' do
      expect { described_class.new(configured_http_proxy.merge(:non_proxy_hostnames => 'example.com')) }.to_not raise_error
    end

    specify 'should accept an empty string' do
      expect { described_class.new(configured_http_proxy.merge(:non_proxy_hostnames => '')) }.to_not raise_error
    end

    specify 'should accept an empty array' do
      expect { described_class.new(configured_http_proxy.merge(:non_proxy_hostnames => [])) }.to_not raise_error
    end

    specify 'should accept array with one element ' do
      expect { described_class.new(configured_http_proxy.merge(:non_proxy_hostnames => ['example.com'])) }.to_not raise_error
    end

    specify 'should accept multiple elements' do
      expect { described_class.new(configured_http_proxy.merge(:non_proxy_hostnames => ['private.example.com', 'internal.example.com'])) }.to_not raise_error
    end

    specify 'should not accept string with comma separated list of hostnames' do
      expect {
        described_class.new(configured_http_proxy.merge(:non_proxy_hostnames => 'private.example.com,internal.example.com'))
      }.to raise_error(Puppet::ResourceError, /Multiple non-proxy hostnames/)
    end
  end
end
