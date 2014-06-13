require 'spec_helper'

describe Puppet::Type.type(:nexus_connection_settings) do
  before :each do
    @provider_class = described_class.provide(:simple) do
      mk_resource_methods
      def flush; end
      def self.instances; []; end
    end
    described_class.stubs(:defaultprovider).returns @provider_class
  end

  describe :connection_timeout do
    specify 'should default to 10' do
      expect(described_class.new(:name => 'any')[:connection_timeout]).to be(10)
    end

    specify 'should accept timeout 0' do
      expect { described_class.new(:name => 'any', :connection_timeout => 0) }.to_not raise_error
    end

    specify 'should accept timeout 1' do
      expect { described_class.new(:name => 'any', :connection_timeout => 1) }.to_not raise_error
    end

    specify 'should accept timeout as string' do
      expect { described_class.new(:name => 'any', :connection_timeout => '60') }.to_not raise_error
    end

    specify 'should not accept negative value' do
      expect {
        described_class.new(:name => 'any', :connection_timeout => -1)
      }.to raise_error(Puppet::ResourceError, /Parameter connection_timeout failed/)
    end

    specify 'should not accept empty string' do
      expect {
        described_class.new(:name => 'any', :connection_timeout => '')
      }.to raise_error(Puppet::ResourceError, /Parameter connection_timeout failed/)
    end

    specify 'should not accept characters' do
      expect {
        described_class.new(:name => 'any', :connection_timeout => 'abc')
      }.to raise_error(Puppet::ResourceError, /Parameter connection_timeout failed/)
    end
  end

  describe :connection_retries do
    specify 'should default to 3' do
      expect(described_class.new(:name => 'any')[:connection_retries]).to be(3)
    end

    specify 'should accept 0 retries' do
      expect { described_class.new(:name => 'any', :connection_retries => 0) }.to_not raise_error
    end

    specify 'should accept 1 retries' do
      expect { described_class.new(:name => 'any', :connection_retries => 1) }.to_not raise_error
    end

    specify 'should accept retries as string' do
      expect { described_class.new(:name => 'any', :connection_retries => '3') }.to_not raise_error
    end

    specify 'should not accept negative value' do
      expect {
        described_class.new(:name => 'any', :connection_retries => -1)
      }.to raise_error(Puppet::ResourceError, /Parameter connection_retries failed/)
    end

    specify 'should not accept empty string' do
      expect {
        described_class.new(:name => 'any', :connection_retries => '')
      }.to raise_error(Puppet::ResourceError, /Parameter connection_retries failed/)
    end

    specify 'should not accept characters' do
      expect {
        described_class.new(:name => 'any', :connection_retries => 'abc')
      }.to raise_error(Puppet::ResourceError, /Parameter connection_retries failed/)
    end
  end

  describe :user_agent_fragment do
    specify 'should be empty by default' do
      expect(described_class.new(:name => 'any')[:user_agent_fragment]).to eq('')
    end

    specify 'should accept valid value' do
      expect { described_class.new(:name => 'any', :user_agent_fragment => 'foobar') }.to_not raise_error
    end

    specify 'should accept empty string' do
      expect { described_class.new(:name => 'any', :user_agent_fragment => '') }.to_not raise_error
    end

    specify 'should accept value with whitespaces' do
      expect { described_class.new(:name => 'any', :user_agent_fragment => 'foo bar') }.to_not raise_error
    end
  end

  describe :query_string do
    specify 'should be empty by default' do
      expect(described_class.new(:name => 'any')[:query_string]).to eq('')
    end

    specify 'should accept valid value' do
      expect { described_class.new(:name => 'any', :query_string => 'foobar') }.to_not raise_error
    end

    specify 'should accept empty string' do
      expect { described_class.new(:name => 'any', :query_string => '') }.to_not raise_error
    end

    specify 'should accept value with whitespaces' do
      expect { described_class.new(:name => 'any', :query_string => 'foo bar') }.to_not raise_error
    end
  end
end
