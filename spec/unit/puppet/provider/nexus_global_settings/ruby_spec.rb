require 'spec_helper'

type_class = Puppet::Type.type(:nexus_global_settings)
provider_class = type_class.provider(:ruby)

describe provider_class do
  let(:force_update) { true }
  before(:each) do
    Nexus::Config.stub(:resolve).and_return('http://example.com/foobar')
  end

  describe 'instances' do
    let :instances do
      Nexus::Rest.should_receive(:get_all).with('/service/local/global_settings/current').and_return({'data' => {}})
      Nexus::Rest.should_receive(:get_all).with('/service/local/global_settings/default').and_return({'data' => {}})
      described_class.instances
    end

    specify { expect(instances).to have(2).items }
    specify 'should raise a human readable error message if the operation failed' do
      Nexus::Rest.should_receive(:get_all).and_raise('Operation failed')
      expect { described_class.instances }.to raise_error(Puppet::Error, /Error while retrieving settings/)
    end
  end

  describe 'flush' do
    specify 'should use /service/local/global_settings/default to update the configuration' do
      @provider = provider_class.new(type_class.new({:name => 'default'}), force_update)
      Nexus::Rest.should_receive(:update).with('/service/local/global_settings/default', anything())
      expect { @provider.flush }.to_not raise_error
    end

    specify 'should raise a human readable error message if the operation failed' do
      @provider = provider_class.new(type_class.new({:name => 'example'}), force_update)
      Nexus::Rest.should_receive(:update).and_raise('Operation failed')
      expect { @provider.flush }.to raise_error(Puppet::Error, /Error while updating nexus_global_settings example/)
    end

    specify 'should map notification_enabled :true to true' do
      @provider = provider_class.new(type_class.new({:name => 'default', :notification_enabled => :true}), force_update)
      Nexus::Rest.should_receive(:update).with(anything, :data => hash_including(:systemNotificationSettings => hash_including(:enabled => true)))
      expect { @provider.flush }.to_not raise_error
    end

    specify 'should map notification_enabled :false to false' do
      @provider = provider_class.new(type_class.new({:name => 'default', :notification_enabled => :false}), force_update)
      Nexus::Rest.should_receive(:update).with(anything, :data => hash_including(:systemNotificationSettings => hash_including(:enabled => false)))
      expect { @provider.flush }.to_not raise_error
    end
  end
end
