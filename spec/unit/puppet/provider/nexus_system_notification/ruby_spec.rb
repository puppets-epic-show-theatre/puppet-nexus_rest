require 'spec_helper'

describe Puppet::Type.type(:nexus_system_notification).provider(:ruby) do
  describe :map_config_to_resource_hash do
    let(:global_config) do
      {
        'systemNotificationSettings' => {
          'enabled'        => true,
          'emailAddresses' => 'john@example.com, jane@example.com',
          'roles'          => ['group-1','group-2']
        }
      }
    end

    let(:resource_hash) do
      described_class::map_config_to_resource_hash(global_config)
    end

    specify { expect(resource_hash[:enabled]).to eq(:true) }
    specify { expect(resource_hash[:emails]).to eq('john@example.com, jane@example.com') }
    specify { expect(resource_hash[:roles]).to eq('group-1,group-2') }
  end

  describe :map_resource_to_config do
    let(:resource) do
      {
        :enabled => :true,
        :emails  => '',
        :roles   => ''
      }
    end

    let(:instance) do
      instance = described_class.new()
      instance.resource = resource
      instance
    end

    specify 'should return all changes within systemNotificationSettings hash' do
      expect(instance.map_resource_to_config.keys).to eq(['systemNotificationSettings'])
    end

    specify 'should map notification_enabled :true to true' do
      resource[:enabled] = :true
      expect(instance.map_resource_to_config['systemNotificationSettings']).to include('enabled' => true)
    end

    specify 'should map notification_enabled :false to false' do
      resource[:enabled] = :false
      expect(instance.map_resource_to_config['systemNotificationSettings']).to include('enabled' => false)
    end

    specify 'should map emails to a flat string' do
      resource[:emails] = 'john@example.com,jane@example.com'
      expect(instance.map_resource_to_config['systemNotificationSettings']).to include('emailAddresses' => 'john@example.com,jane@example.com')
    end

    specify 'should map roles to an array' do
      resource[:roles] = 'group-1,group-2'
      expect(instance.map_resource_to_config['systemNotificationSettings']).to include('roles' => ['group-1','group-2'])
    end
  end
end
