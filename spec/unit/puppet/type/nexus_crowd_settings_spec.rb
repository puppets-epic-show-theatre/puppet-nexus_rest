require 'spec_helper'

describe Puppet::Type.type(:nexus_crowd_settings) do
  before :each do
    @provider_class = described_class.provide(:simple) do
      mk_resource_methods
      def flush; end
      def self.instances; []; end
    end
    described_class.stubs(:defaultprovider).returns @provider_class
  end

  describe :application_name do
    specify 'should accept string' do
      expect { described_class.new(:name => 'current', :application_name => 'ABC') }.to_not raise_error
    end

    specify 'should not accept empty string' do
      expect { described_class.new(:name => 'current', :application_name => '') }.to raise_error
    end

    specify 'should reject false' do
      expect { described_class.new(:name => 'current', :application_name => false) }.to raise_error
    end

    specify 'should reject nil' do
      expect { described_class.new(:name => 'current', :application_name => nil) }.to raise_error
    end
  end

  describe :application_password do
    specify 'should default to :absent' do
      expect(described_class.new(:name => 'any')[:application_password]).to eq(:absent)
    end

    specify 'should accept :present' do
      expect { described_class.new(:name => 'any', :application_password => :present) }.to_not raise_error
    end

    specify 'should accept :absent' do
      expect { described_class.new(:name => 'any', :application_password => :absent) }.to_not raise_error
    end

    specify 'should not accept anything else' do
      expect {
        described_class.new(:name => 'any', :application_password => 'secret')
      }.to raise_error(Puppet::ResourceError, /Parameter application_password failed/)
    end
  end

  describe :application_password_value do
    specify 'should accept string' do
      expect { described_class.new(:name => 'current', :application_password_value => 'ABC') }.to_not raise_error
    end

    specify 'should not accept empty string' do
      expect { described_class.new(:name => 'current', :application_password_value => '') }.to raise_error
    end

    specify 'should reject false' do
      expect { described_class.new(:name => 'current', :application_password_value => false) }.to raise_error
    end

    specify 'should reject nil' do
      expect { described_class.new(:name => 'current', :application_password_value => nil) }.to raise_error
    end
  end

  describe :crowd_server_url do
    specify 'should accept http://example.com' do
      expect { described_class.new(:name => 'any', :crowd_server_url => 'http://example.com') }.to_not raise_error
    end

    specify 'should accept http://example.com' do
      expect { described_class.new(:name => 'any', :crowd_server_url => 'http://example.com') }.to_not raise_error
    end

    specify 'should not accept an invalid url' do
      expect {
        described_class.new(:name => 'any', :crowd_server_url => 'invalid')
      }.to raise_error(Puppet::ResourceError, /Parameter crowd_server_url failed/)
    end

    specify 'should reject nil' do
      expect { described_class.new(:name => 'current', :crowd_server_url => nil) }.to raise_error
    end

    specify 'should not accept empty string' do
      expect {
        described_class.new(:name => 'any', :crowd_server_url => '')
      }.to raise_error(Puppet::ResourceError, /Parameter crowd_server_url failed/)
    end
  end

  describe :http_timeout do
    specify 'should default to 60' do
      expect(described_class.new(:name => 'any')[:http_timeout]).to eq(60)
    end

    specify 'should accept 0' do
      expect { described_class.new(:name => 'any', :http_timeout => 0) }.to_not raise_error
    end

    specify 'should accept 1' do
      expect { described_class.new(:name => 'any', :http_timeout => 1) }.to_not raise_error
    end

    specify 'should accept 100' do
      expect { described_class.new(:name => 'any', :http_timeout => 100) }.to_not raise_error
    end

    specify 'should accept http_timeout as string' do
      expect { described_class.new(:name => 'any', :http_timeout => '1') }.to_not raise_error
    end

    specify 'should not accept empty string' do
      expect {
        described_class.new(:name => 'any', :http_timeout => '')
      }.to raise_error(Puppet::ResourceError, /Parameter http_timeout failed/)
    end

    specify 'should not accept negative number' do
      expect {
        described_class.new(:name => 'any', :http_timeout => -1)
      }.to raise_error(Puppet::ResourceError, /Parameter http_timeout failed/)
    end

    specify 'should not accept characters' do
      expect {
        described_class.new(:name => 'any', :http_timeout => 'abc')
      }.to raise_error(Puppet::ResourceError, /Parameter http_timeout failed/)
    end
  end

end