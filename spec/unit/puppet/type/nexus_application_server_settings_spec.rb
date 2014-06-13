require 'spec_helper'

describe Puppet::Type.type(:nexus_application_server_settings) do
  before :each do
    @provider_class = described_class.provide(:simple) do
      mk_resource_methods
      def flush; end
      def self.instances; []; end
    end
    described_class.stubs(:defaultprovider).returns @provider_class
  end

  describe :baseurl do
    specify 'should accept http://example.com' do
      expect { described_class.new(:name => 'any', :baseurl => 'http://example.com') }.to_not raise_error
    end

    specify 'should accept https://example.com' do
      expect { described_class.new(:name => 'any', :baseurl => 'https://example.com') }.to_not raise_error
    end

    specify 'should not accept empty string' do
      expect {
        described_class.new(:name => 'any', :baseurl => '')
      }.to raise_error(Puppet::ResourceError, /Parameter baseurl failed/)
    end

    specify 'should not accept invalid url' do
      expect {
        described_class.new(:name => 'any', :baseurl => 'invalid')
      }.to raise_error(Puppet::ResourceError, /Parameter baseurl failed/)
    end
  end

  describe :forceurl do
    specify 'should default to false' do
      expect(described_class.new(:name => 'any')[:forceurl]).to eq(:false)
    end

    specify 'should accept :true' do
      expect { described_class.new(:name => 'any', :forceurl => :true) }.to_not raise_error
    end

    specify 'should accept :false' do
      expect { described_class.new(:name => 'any', :forceurl => :false) }.to_not raise_error
    end

    specify 'should not accept empty string' do
      expect {
        described_class.new(:name => 'any', :forceurl => '')
      }.to raise_error(Puppet::ResourceError, /Parameter forceurl failed/)
    end
  end

  describe :timeout do
    specify 'should default to 60' do
      expect(described_class.new(:name => 'any')[:timeout]).to eq(60)
    end

    specify 'should accept 0' do
      expect { described_class.new(:name => 'any', :timeout => 0) }.to_not raise_error
    end

    specify 'should accept 1' do
      expect { described_class.new(:name => 'any', :timeout => 1) }.to_not raise_error
    end

    specify 'should accept 100' do
      expect { described_class.new(:name => 'any', :timeout => 100) }.to_not raise_error
    end

    specify 'should accept timeout as string' do
      expect { described_class.new(:name => 'any', :timeout => '1') }.to_not raise_error
    end

    specify 'should not accept empty string' do
      expect {
        described_class.new(:name => 'any', :timeout => '')
      }.to raise_error(Puppet::ResourceError, /Parameter timeout failed/)
    end

    specify 'should not accept negative number' do
      expect {
        described_class.new(:name => 'any', :timeout => -1)
      }.to raise_error(Puppet::ResourceError, /Parameter timeout failed/)
    end

    specify 'should not accept characters' do
      expect {
        described_class.new(:name => 'any', :timeout => 'abc')
      }.to raise_error(Puppet::ResourceError, /Parameter timeout failed/)
    end
  end
end
