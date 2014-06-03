require 'spec_helper'

describe Puppet::Type.type(:nexus_system_notification) do
  before :each do
    @provider_class = described_class.provide(:simple) do
      mk_resource_methods
      def flush; end
      def self.instances; []; end
    end
    described_class.stubs(:defaultprovider).returns @provider_class
  end

  describe :enabled do
    specify 'should default to false' do
      expect(described_class.new(:name => 'any')[:enabled]).to eq(:false)
    end

    specify 'should accept true' do
      expect { described_class.new(:name => 'any', :enabled => true) }.to_not raise_error
    end

    specify 'should accept :true' do
      expect { described_class.new(:name => 'any', :enabled => :true) }.to_not raise_error
    end

    specify 'should accept "true"' do
      expect { described_class.new(:name => 'any', :enabled => 'true') }.to_not raise_error
    end

    specify 'should accept false' do
      expect { described_class.new(:name => 'any', :enabled => false) }.to_not raise_error
    end

    specify 'should accept :false' do
      expect { described_class.new(:name => 'any', :enabled => :false) }.to_not raise_error
    end

    specify 'should accept "false"' do
      expect { described_class.new(:name => 'any', :enabled => 'false') }.to_not raise_error
    end

    specify 'should not accept empty string' do
      expect {
        described_class.new(:name => 'any', :enabled => '')
      }.to raise_error(Puppet::ResourceError, /Parameter enabled failed/)
    end
  end

  describe :emails do
    specify 'should default to empty string' do
      expect(described_class.new(:name => 'any')[:emails]).to eq('')
    end

    specify 'should accept a single string' do
      expect { described_class.new(:name => 'any', :emails => 'jdoe@example.com') }.to_not raise_error
    end

    specify 'should accept an empty string' do
      expect { described_class.new(:name => 'any', :emails => '') }.to_not raise_error
    end

    specify 'should accept an empty array' do
      expect { described_class.new(:name => 'any', :emails => []) }.to_not raise_error
    end

    specify 'should accept multiple elements' do
      expect { described_class.new(:name => 'any', :emails => ['jdoe@example.com']) }.to_not raise_error
      expect { described_class.new(:name => 'any', :emails => ['john@example.com', 'jane@example.com']) }.to_not raise_error
    end

    specify 'should not accept invalid email addresses' do
      expect {
        described_class.new(:name => 'any', :emails => ['fail'])
      }.to raise_error(Puppet::ResourceError, /Invalid email address 'fail'/)
    end

    specify 'should not accept string with comma separated list of email addresses' do
      expect {
        described_class.new(:name => 'any', :emails => 'john@example.com,jane@example.com')
      }.to raise_error(Puppet::ResourceError, /Multiple email addresses/)
    end
  end

  describe :roles do
    specify 'should default to empty string' do
      expect(described_class.new(:name => 'any')[:roles]).to eq('')
    end

    specify 'should accept a single string' do
      expect { described_class.new(:name => 'any', :roles => 'admins') }.to_not raise_error
    end

    specify 'should accept an empty string' do
      expect { described_class.new(:name => 'any', :roles => '') }.to_not raise_error
    end

    specify 'should accept an empty array' do
      expect { described_class.new(:name => 'any', :roles => []) }.to_not raise_error
    end

    specify 'should accept multiple elements' do
      expect { described_class.new(:name => 'any', :roles => ['admins']) }.to_not raise_error
      expect { described_class.new(:name => 'any', :roles => ['admins', 'users']) }.to_not raise_error
    end

    specify 'should not accept string with comma separated list of roles' do
      expect {
        described_class.new(:name => 'any', :roles => 'admins,users')
      }.to raise_error(Puppet::ResourceError, /Multiple roles/)
    end
  end
end
