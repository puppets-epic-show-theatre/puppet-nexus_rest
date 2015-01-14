require 'spec_helper'

describe Puppet::Type.type(:nexus_staging_ruleset) do
  let(:defaults) { {:name => 'any', :rules => 'any'} }

  before :each do
    @provider_class = described_class.provide(:simple) do
      mk_resource_methods
      def flush; end
      def self.instances; []; end
    end
    described_class.stubs(:defaultprovider).returns @provider_class
  end

  describe :ensure do
    specify 'should accept present' do
      expect { described_class.new(defaults.merge(:ensure => :present)) }.to_not raise_error
    end

    specify 'should accept absent' do
      expect { described_class.new(defaults.merge(:ensure => :absent)) }.to_not raise_error
    end
  end

  describe :description do
    specify 'should default to empty string' do
      expect(described_class.new(defaults)[:description]).to eq('')
    end

    specify 'should accept empty string' do
      expect { described_class.new(defaults.merge(:description => '')) }.to_not raise_error
    end

    specify 'should accept meaningful description' do
      expect { described_class.new(defaults.merge(:description => 'Release Candidates')) }.to_not raise_error
    end
  end

  describe :rules do
    specify 'is mandatory when ensure => present' do
      defaults.delete(:rules)

      expect { described_class.new(defaults.merge(:ensure => :present)) }.to raise_error(Puppet::Error, /mandatory property/)
    end

    specify 'should not accept empty array' do
      expect { described_class.new(defaults.merge(:rules => [])) }.to raise_error(Puppet::Error, /not be empty/)
    end

    specify 'should not accept empty string' do
      expect { described_class.new(defaults.merge(:rules => '')) }.to raise_error(Puppet::Error, /not be empty/)
    end

    specify 'should accept single string' do
      expect { described_class.new(defaults.merge(:rules => 'rule-A')) }.to_not raise_error
    end

    specify 'should not accept string with comma separate list of elements' do
      expect { described_class.new(defaults.merge(:rules => 'rule-A,rule-B')) }.to raise_error(Puppet::Error, /must be provided as an array/)
    end

    specify 'should accept array with single element' do
      expect { described_class.new(defaults.merge(:rules => ['rule-A'])) }.to_not raise_error
    end

    specify 'should accept array multiple elements' do
      expect { described_class.new(defaults.merge(:rules => ['rule-A', 'rule-B'])) }.to_not raise_error
    end

    specify 'should not be validated when ensure => absent' do
      expect { described_class.new(defaults.merge(:rules => [], :ensure => :absent)) }.to_not raise_error
    end
  end
end
