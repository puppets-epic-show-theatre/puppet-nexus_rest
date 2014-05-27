require 'spec_helper'

describe Puppet::Type.type(:nexus_smtp_settings) do
  before :each do
    @provider_class = described_class.provide(:simple) do
      mk_resource_methods
      def flush; end
      def self.instances; []; end
    end
    described_class.stubs(:defaultprovider).returns @provider_class
  end

  describe :hostname do
    specify 'should accept a valid hostname' do
      expect { described_class.new(:name => 'any', :hostname => 'smtp.example.com') }.to_not raise_error
    end

    specify 'should accept a localhost' do
      expect { described_class.new(:name => 'any', :hostname => 'localhost') }.to_not raise_error
    end

    specify 'should not accept empty string' do
      expect {
        described_class.new(:name => 'any', :hostname => '')
      }.to raise_error(Puppet::ResourceError, /Parameter hostname failed/)
    end
  end

  describe :port do
    specify 'should default to 25' do
      expect(described_class.new(:name => 'any')[:port]).to be(25)
    end

    specify 'should not accept empty string' do
      expect {
        described_class.new(:name => 'any', :port => '')
      }.to raise_error(Puppet::ResourceError, /Parameter port failed/)
    end

    specify 'should not accept characters' do
      expect {
        described_class.new(:name => 'any', :port => 'abc')
      }.to raise_error(Puppet::ResourceError, /Parameter port failed/)
    end

    specify 'should not accept port 0' do
      expect {
        described_class.new(:name => 'any', :port => 0)
      }.to raise_error(Puppet::ResourceError, /Parameter port failed/)
    end

    specify 'should accept port 1' do
      expect { described_class.new(:name => 'any', :port => 1) }.to_not raise_error
    end

    specify 'should accept port as string' do
      expect { described_class.new(:name => 'any', :port => '25') }.to_not raise_error
    end

    specify 'should accept port 65535' do
      expect { described_class.new(:name => 'any', :port =>  65535) }.to_not raise_error
    end

    specify 'should not accept ports larger than 65535' do
      expect {
        described_class.new(:name => 'any', :port =>  65536)
      }.to raise_error(Puppet::ResourceError, /Parameter port failed/)
    end
  end

  describe :username do
    specify 'should default to empty string' do
      expect(described_class.new(:name => 'any')[:username]).to eq('')
    end

    specify 'should accept empty string' do
      expect { described_class.new(:name => 'any', :username => '') }.to_not raise_error
    end

    specify 'should accept valid username' do
      expect { described_class.new(:name => 'any', :username => 'jdoe') }.to_not raise_error
    end
  end

  describe :password do
    specify 'should default to :absent' do
      expect(described_class.new(:name => 'any')[:password]).to eq(:absent)
    end

    specify 'should accept :present' do
      expect { described_class.new(:name => 'any', :password => :present) }.to_not raise_error
    end

    specify 'should accept :absent' do
      expect { described_class.new(:name => 'any', :password => :absent) }.to_not raise_error
    end

    specify 'should not accept anything else' do
      expect {
        described_class.new(:name => 'any', :password => 'secret')
      }.to raise_error(Puppet::ResourceError, /Parameter password failed/)
    end
  end

  describe :password_value do
    specify 'should default to secret' do
      expect(described_class.new(:name => 'any')[:password_value]).to eq('secret')
    end

    specify 'should accept empty string' do
      expect { described_class.new(:name => 'any', :password_value => '') }.to_not raise_error
    end

    specify 'should accept valid value' do
      expect { described_class.new(:name => 'any', :password_value => 'secret') }.to_not raise_error
    end
  end

  describe :communication_security do
    specify 'should default to :none' do
      expect(described_class.new(:name => 'any')[:communication_security]).to eq(:none)
    end

    specify 'should accept :none' do
      expect { described_class.new(:name => 'any', :communication_security => :none) }.to_not raise_error
    end

    specify 'should accept none' do
      expect { described_class.new(:name => 'any', :communication_security => 'none') }.to_not raise_error
    end

    specify 'should accept :ssl' do
      expect { described_class.new(:name => 'any', :communication_security => :ssl) }.to_not raise_error
    end

    specify 'should accept ssl' do
      expect { described_class.new(:name => 'any', :communication_security => 'ssl') }.to_not raise_error
    end

    specify 'should accept :tls' do
      expect { described_class.new(:name => 'any', :communication_security => :tls) }.to_not raise_error
    end

    specify 'should accept tls' do
      expect { described_class.new(:name => 'any', :communication_security => 'tls') }.to_not raise_error
    end

    specify 'should not accept empty string' do
      expect {
        described_class.new(:name => 'any', :communication_security => '')
      }.to raise_error(Puppet::ResourceError, /Parameter communication_security failed/)
    end

    specify 'should not accept arbitrary string' do
      expect {
        described_class.new(:name => 'any', :communication_security => 'invalid')
      }.to raise_error(Puppet::ResourceError, /Parameter communication_security failed/)
    end
  end

  describe :sender_email do
    specify 'should accept valid email address' do
      expect { described_class.new(:name => 'any', :sender_email => 'jdoe@example.com') }.to_not raise_error
    end

    specify 'should not accept empty email address' do
      expect {
        described_class.new(:name => 'any', :sender_email => '')
      }.to raise_error(Puppet::ResourceError, /Parameter sender_email failed/)
    end

    specify 'should not accept invalid email address' do
      expect {
        described_class.new(:name => 'any', :sender_email => 'invalid')
      }.to raise_error(Puppet::ResourceError, /Parameter sender_email failed/)
    end
  end

  describe :use_nexus_trust_store do
    specify 'should default to false' do
      expect(described_class.new(:name => 'any')[:use_nexus_trust_store]).to be_false
    end

    specify 'should accept :true' do
      expect { described_class.new(:name => 'any', :use_nexus_trust_store => :true) }.to_not raise_error
    end

    specify 'should accept :false' do
      expect { described_class.new(:name => 'any', :use_nexus_trust_store => :false) }.to_not raise_error
    end
  end
end
