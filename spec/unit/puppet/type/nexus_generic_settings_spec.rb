require 'spec_helper'

describe Puppet::Type.type(:nexus_generic_settings) do
  before :each do
    @provider_class = described_class.provide(:simple) do
      mk_resource_methods
      def flush; end
      def self.instances; []; end
    end
    described_class.stubs(:defaultprovider).returns @provider_class
  end

  describe :api_url_fragment do
    specify 'should accept a url fragment' do
      expect { described_class.new(:name => 'any', :api_url_fragment => '/service/local/global_settings/current') }.to_not raise_error
    end

    specify 'should not accept empty string' do
      expect {
        described_class.new(:name => 'any', :api_url_fragment => '')
      }.to raise_error(Puppet::ResourceError, /Parameter api_url_fragment failed/)
    end
  end

  describe :merge do
    specify 'should default to false' do
      expect(described_class.new(:name => 'any')[:merge]).to be_false
    end

    specify 'should accept :true' do
      expect { described_class.new(:name => 'any', :merge => :true) }.to_not raise_error
    end

    specify 'should accept :false' do
      expect { described_class.new(:name => 'any', :merge => :false) }.to_not raise_error
    end
  end

  describe :id_field do
    specify 'should default to "id"' do
      expect(described_class.new(:name => 'any')[:id_field]).to eq('id')
    end

    specify 'should accept valid field name' do
      expect { described_class.new(:name => 'any', :id_field => 'userId') }.to_not raise_error
    end
  end

  describe :settings_hash do
    specify 'should accept a valid hash' do
      expect { described_class.new(:name => 'any', :settings_hash => { :foo => 'bar' }) }.to_not raise_error
    end
  end

  describe :action do
    specify 'should default to :update' do
      expect(described_class.new(:name => 'any')[:action]).to eq(:update)
    end

    specify 'should accept :update' do
      expect { described_class.new(:name => 'any', :action => :update) }.to_not raise_error
    end

    specify 'should accept :create' do
      expect { described_class.new(:name => 'any', :action => :create) }.to_not raise_error
    end

    specify 'should not accept anything else' do
      expect {
        described_class.new(:name => 'any', :action => 'dasdasd')
      }.to raise_error(Puppet::ResourceError, /Parameter action failed/)
    end
  end
end
