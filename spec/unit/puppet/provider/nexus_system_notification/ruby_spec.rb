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
    described_class.new(resource)
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

  describe :flush do
    before (:each) do
      Nexus::Config.stub(:resolve).and_return('http://example.com/foobar')
      Nexus::Rest.stub(:get_all).and_return({'data' => {'otherdata' => 'foobar'}})
    end

    specify 'should raise a human readable error message if the operation failed' do
      provider.mark_system_notifications_dirty
      Nexus::Rest.should_receive(:update).and_raise('Operation failed')
      expect { provider.flush}.to raise_error(Puppet::Error, /Error while updating nexus_system_notification default/)
    end
  end

  describe :update_system_notifications do
    before (:each) do
      Nexus::Config.stub(:resolve).and_return('http://example.com/foobar')
      Nexus::Rest.stub(:get_all).and_return({'data' => {'otherdata' => 'foobar'}})
    end

    specify 'should use /service/local/global_settings/default to update the configuration' do
      Nexus::Rest.should_receive(:update).with('/service/local/global_settings/default', anything())
      expect { provider.update_system_notifications }.to_not raise_error
    end

    specify 'should add unmanaged parts of the current configuration with the new one' do
      Nexus::Rest.should_receive(:update).with(anything, 'data' => hash_including('otherdata' => 'foobar'))
      expect { provider.update_system_notifications }.to_not raise_error
    end

    specify 'should call REST_RESOURCE to fetch the current configuration' do
      Nexus::Rest.stub(:update)
      Nexus::Rest.should_receive(:get_all).with('/service/local/global_settings/default')
      expect { provider.update_system_notifications }.to_not raise_error
    end

    specify 'should map notification_enabled :true to true' do
      resource[:enabled] = :true
      Nexus::Rest.should_receive(:update).with(anything, 'data' => hash_including('systemNotificationSettings' => hash_including('enabled' => true)))
      expect { provider.update_system_notifications }.to_not raise_error
    end

    specify 'should map notification_enabled :false to false' do
      resource[:enabled] = :false
      Nexus::Rest.should_receive(:update).with(anything, 'data' => hash_including('systemNotificationSettings' => hash_including('enabled' => false)))
      expect { provider.update_system_notifications }.to_not raise_error
    end

    specify 'should map emails to a flat string' do
      resource[:emails] = ['john@example.com', 'jane@example.com']
      Nexus::Rest.should_receive(:update).with(anything, 'data' => hash_including('systemNotificationSettings' => hash_including('emailAddresses' => 'jane@example.com,john@example.com')))
      expect { provider.update_system_notifications }.to_not raise_error
    end

    specify 'should map roles to an array' do
      resource[:roles] = ['group-1','group-2']
      Nexus::Rest.should_receive(:update).with(anything, 'data' => hash_including('systemNotificationSettings' => hash_including('roles' => ['group-1','group-2'])))
      expect { provider.update_system_notifications }.to_not raise_error
    end
  end
end
