require 'spec_helper'

type_class = Puppet::Type.type(:nexus_system_notification)
provider_class = type_class.provider(:ruby)

describe provider_class do
  let(:force_update) { true }
  before(:each) do
    Nexus::Config.stub(:resolve).and_return('http://example.com/foobar')
  end

  let(:resource) do
    resource = type_class.new({
      :name    => 'default',
      :enabled => :true,
      :emails  => [],
      :roles   => []
    })
  end
  let(:provider) do
    described_class.new(resource, force_update)
  end

  describe 'instances' do
    let(:instances) do
      Nexus::Rest.should_receive(:get_all).with('/service/local/global_settings/current').and_return({
        'data' => {
          'systemNotificationSettings' => {
            'enabled'        => true,
            'emailAddresses' => 'john@example.com, jane@example.com',
            'roles'          => ['group-1','group-2']
          }
        }
      })
      described_class.instances
    end
    let(:current_settings) { instances[0] }

    specify { expect(instances).to have(1).items }
    specify 'should raise a human readable error message if the operation failed' do
      Nexus::Rest.should_receive(:get_all).and_raise('Operation failed')
      expect { described_class.instances }.to raise_error(Puppet::Error, /Error while retrieving settings/)
    end
    specify { expect(current_settings.name).to eq('current') }
    specify { expect(current_settings.enabled).to eq(:true) }
    specify { expect(current_settings.emails).to eq('john@example.com, jane@example.com') }
    specify { expect(current_settings.roles).to eq('group-1,group-2') }
  end

  describe 'flush' do
    specify 'should use /service/local/global_settings/default to update the configuration' do
      Nexus::Rest.should_receive(:update).with('/service/local/global_settings/default', anything())
      expect { provider.flush }.to_not raise_error
    end

    specify 'should raise a human readable error message if the operation failed' do
      Nexus::Rest.should_receive(:update).and_raise('Operation failed')
      expect { provider.flush }.to raise_error(Puppet::Error, /Error while updating nexus_system_notification default/)
    end

    specify 'should map notification_enabled :true to true' do
      resource[:enabled] = :true
      Nexus::Rest.should_receive(:update).with(anything, :data => hash_including(:systemNotificationSettings => hash_including(:enabled => true)))
      expect { provider.flush }.to_not raise_error
    end

    specify 'should map notification_enabled :false to false' do
      resource[:enabled] = :false
      Nexus::Rest.should_receive(:update).with(anything, :data => hash_including(:systemNotificationSettings => hash_including(:enabled => false)))
      expect { provider.flush }.to_not raise_error
    end
  end
end
