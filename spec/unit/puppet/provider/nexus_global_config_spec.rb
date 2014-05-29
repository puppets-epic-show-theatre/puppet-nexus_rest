require 'spec_helper'
require 'puppet/provider/nexus_global_config'

describe Puppet::Provider::NexusGlobalConfig do
  before(:each) do
    Nexus::Config.stub(:resolve).and_return('http://example.com/foobar')
    Nexus::Rest.stub(:get_all).and_return({'data' => {'otherdata' => 'foobar'}})
    described_class.stub(:map_config_to_resource_hash).and_return({})
  end

  describe 'instances' do
    specify { expect(described_class.instances).to have(1).items }
    specify 'should raise a human readable error message if the operation failed' do
      Nexus::Rest.should_receive(:get_all).and_raise('Operation failed')
      expect { described_class.instances }.to raise_error(Puppet::Error, /Error while retrieving global configuration 'current'/)
    end
  end

  describe :flush do
    let(:instance) do
      instance = described_class.new()
      instance.resource = {:name => 'example'}
      instance.stub(:map_resource_to_config).and_return({})
      instance
    end

    specify 'should raise a human readable error message if the operation failed' do
      instance.mark_config_dirty
      Nexus::Rest.should_receive(:update).and_raise('Operation failed')
      expect { instance.flush }.to raise_error(Puppet::Error, /Error while updating global configuration 'example'/)
    end

    specify 'should use /service/local/global_settings/default to update the configuration' do
      instance.mark_config_dirty
      Nexus::Rest.should_receive(:update).with('/service/local/global_settings/example', anything())
      expect { instance.flush }.to_not raise_error
    end

    specify 'should add unmanaged parts of the current configuration with the new one' do
      instance.mark_config_dirty
      Nexus::Rest.should_receive(:update).with(anything, 'data' => hash_including('otherdata' => 'foobar'))
      expect { instance.flush }.to_not raise_error
    end

    specify 'should call REST_RESOURCE to fetch the current configuration' do
      instance.mark_config_dirty
      Nexus::Rest.stub(:update)
      Nexus::Rest.should_receive(:get_all).with('/service/local/global_settings/example')
      expect { instance.flush }.to_not raise_error
    end
  end
end
