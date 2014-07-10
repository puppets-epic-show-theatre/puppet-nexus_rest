require 'spec_helper'

describe Puppet::Type.type(:nexus_scheduled_task).provider(:ruby) do
  let(:empty_trash_task_details) do
    {
      'id'         => '1',
      'name'       => 'Empty Trash',
      'enabled'    => true,
      'typeId'     => 'EmptyTrashTask',
      'schedule'   => 'manual',
      'properties' => [
        {
          'key'   => 'EmptyTrashItemsOlderThan',
          'value' => ''
        },
        {
          'key'   => 'repositoryId',
          'value' => 'all_repo'
        }
      ]
    }
  end

  let(:resource) do
    {
      :name            => 'Empty Trash',
      :enabled         => :true,
      :type_id         => 'EmptyTrashTask',
      :reoccurrence    => :manual,
      :task_settings   => 'EmptyTrashItemsOlderThan=;repositoryId=all_repo',
      :start_date      => 1385242260000,
      :recurring_day   => 'sunday',
      :recurring_time  => '21:31',
    }
  end

  let(:instance) do
    instance = described_class.new()
    instance.resource = resource
    instance
  end

  before(:each) do
    Nexus::Config.stub(:resolve).and_return('http://example.com/foobar')
    Nexus::Rest.stub(:get_all).and_return({'data' => {'otherdata' => 'foobar'}})
  end

  describe :instances do
    specify do
      Nexus::Rest.should_receive(:get_all_plus_n).with('/service/local/schedules').and_return({'data' => [{'id' => '1'}, {'id' => '2'}]})

      expect(described_class.instances).to have(2).items
    end

    specify do
      Nexus::Rest.should_receive(:get_all_plus_n).and_raise('Operation failed')

      expect { described_class.instances }.to raise_error(Puppet::Error, /Error while retrieving all nexus_scheduled_task instances/)
    end

    specify 'should set ensure to present' do
      Nexus::Rest.should_receive(:get_all_plus_n).and_return({'data' => [empty_trash_task_details]})

      expect(described_class.instances[0].ensure).to eq(:present)
    end

    specify 'should retrieve id' do
      Nexus::Rest.should_receive(:get_all_plus_n).and_return({'data' => [empty_trash_task_details]})

      expect(described_class.instances[0].id).to eq('1')
    end

    specify 'should retrieve name' do
      Nexus::Rest.should_receive(:get_all_plus_n).and_return({'data' => [empty_trash_task_details]})

      expect(described_class.instances[0].name).to eq('Empty Trash')
    end

    specify 'should map enabled => true to :true' do
      Nexus::Rest.should_receive(:get_all_plus_n).and_return({'data' => [empty_trash_task_details]})

      expect(described_class.instances[0].enabled).to eq(:true)
    end

    specify 'should map enabled => false to :false' do
      Nexus::Rest.should_receive(:get_all_plus_n).and_return({'data' => [empty_trash_task_details.merge('enabled' => false)]})

      expect(described_class.instances[0].enabled).to eq(:false)
    end

    specify 'should map typeId to type_id' do
      Nexus::Rest.should_receive(:get_all_plus_n).and_return({'data' => [empty_trash_task_details]})

      expect(described_class.instances[0].type_id).to eq('EmptyTrashTask')
    end

    specify 'should map absent alert_email to :absent' do
      Nexus::Rest.should_receive(:get_all_plus_n).and_return({'data' => [empty_trash_task_details]})

      expect(described_class.instances[0].alert_email).to eq(:absent)
    end

    specify 'should map absent alertEmail to alert_email' do
      Nexus::Rest.should_receive(:get_all_plus_n).and_return({'data' => [empty_trash_task_details.merge('alertEmail' => 'ops@example.com')]})

      expect(described_class.instances[0].alert_email).to eq('ops@example.com')
    end

    specify 'should map schedule to reoccurrence' do
      Nexus::Rest.should_receive(:get_all_plus_n).and_return({'data' => [empty_trash_task_details]})

      expect(described_class.instances[0].reoccurrence).to eq(:manual)
    end

    specify 'should map properties to task_settings' do
      Nexus::Rest.should_receive(:get_all_plus_n).and_return({'data' => [empty_trash_task_details]})

      expect(described_class.instances[0].task_settings).to eq('EmptyTrashItemsOlderThan=;repositoryId=all_repo')
    end

    specify 'should map absent start_date to :absent' do
      Nexus::Rest.should_receive(:get_all_plus_n).and_return({'data' => [empty_trash_task_details]})

      expect(described_class.instances[0].start_date).to be(:absent)
    end

    specify 'should map startDate to start_date' do
      Nexus::Rest.should_receive(:get_all_plus_n).and_return({'data' => [empty_trash_task_details.merge('startDate' => '1385242260000')]})

      expect(described_class.instances[0].start_date).to eq(1385242260000)
    end

    specify 'should map absent start_time to :absent' do
      Nexus::Rest.should_receive(:get_all_plus_n).and_return({'data' => [empty_trash_task_details]})

      expect(described_class.instances[0].start_time).to be(:absent)
    end

    specify 'should map startTime to start_time' do
      Nexus::Rest.should_receive(:get_all_plus_n).and_return({'data' => [empty_trash_task_details.merge('startTime' => '1:23')]})

      expect(described_class.instances[0].start_time).to eq('1:23')
    end

    specify 'should map absent recurring_day to :absent' do
      Nexus::Rest.should_receive(:get_all_plus_n).and_return({'data' => [empty_trash_task_details]})

      expect(described_class.instances[0].recurring_day).to be(:absent)
    end

    specify 'should map recurringDay list to recurring_day string' do
      Nexus::Rest.should_receive(:get_all_plus_n).and_return({'data' => [empty_trash_task_details.merge('recurringDay' => ['monday', 'friday', 'saturday'])]})

      expect(described_class.instances[0].recurring_day).to eq('monday,friday,saturday')
    end

    specify 'should map absent recurring_time to :absent' do
      Nexus::Rest.should_receive(:get_all_plus_n).and_return({'data' => [empty_trash_task_details]})

      expect(described_class.instances[0].recurring_time).to be(:absent)
    end

    specify 'should map recurringTime to recurring_time' do
      Nexus::Rest.should_receive(:get_all_plus_n).and_return({'data' => [empty_trash_task_details.merge('recurringTime' => '23:59')]})

      expect(described_class.instances[0].recurring_time).to eq('23:59')
    end

    specify 'should map absent cron_expression to :absent' do
      Nexus::Rest.should_receive(:get_all_plus_n).and_return({'data' => [empty_trash_task_details]})

      expect(described_class.instances[0].cron_expression).to be(:absent)
    end

    specify 'should map cronCommand to cron_expression' do
      Nexus::Rest.should_receive(:get_all_plus_n).and_return({'data' => [empty_trash_task_details.merge('cronCommand' => '0 0 12 * * ?')]})

      expect(described_class.instances[0].cron_expression).to eq('0 0 12 * * ?')
    end
  end

  describe :create do
    specify 'should use /service/local/schedules to create a new resource' do
      Nexus::Rest.should_receive(:create).with('/service/local/schedules', anything())

      expect { instance.create }.to_not raise_error
    end

    specify 'should raise a human readable error message if the operation failed' do
      Nexus::Rest.should_receive(:create).and_raise('Operation failed')

      expect { instance.create }.to raise_error(Puppet::Error, /Error while creating Nexus_scheduled_task\['Empty Trash'\]/)
    end
  end

  describe :map_resource_to_data do
    specify 'should return all changes within data hash' do
      expect(instance.map_resource_to_data.keys).to eq(['data'])
    end

    specify do
      resource[:id] = :absent

      expect(instance.map_resource_to_data['data']).to_not include('id')
    end

    specify do
      resource[:id] = 'a1b2'

      expect(instance.map_resource_to_data['data']).to include('id' => 'a1b2')
    end

    specify do
      resource[:name] = 'Empty Trash'

      expect(instance.map_resource_to_data['data']).to include('name' => 'Empty Trash')
    end

    specify do
      resource[:enabled] = :true

      expect(instance.map_resource_to_data['data']).to include('enabled' => true)
    end

    specify do
      resource[:enabled] = :false

      expect(instance.map_resource_to_data['data']).to include('enabled' => false)
    end

    specify do
      resource[:type_id] = 'EmptyTrashTask'

      expect(instance.map_resource_to_data['data']).to include('typeId' => 'EmptyTrashTask')
    end

    specify do
      resource[:alert_email] = :absent

      expect(instance.map_resource_to_data['data']).to_not include('alertEmail')
    end

    specify do
      resource[:alert_email] = 'ops@example.com'

      expect(instance.map_resource_to_data['data']).to include('alertEmail' => 'ops@example.com')
    end

    specify do
      resource[:schedule] = :manual

      expect(instance.map_resource_to_data['data']).to include('schedule' => 'manual')
    end

    specify do
      expect(instance.map_resource_to_data['data']).to include('properties' => [
        {'key'=> 'EmptyTrashItemsOlderThan', 'value' => ''},
        {'key' => 'repositoryId', 'value' => 'all_repo'}
      ])
    end

    specify do
      resource[:start_date] = 1385242260000

      expect(instance.map_resource_to_data['data']).to include('startDate' => '1385242260000')
    end

    specify do
      resource[:start_date] = :absent

      expect(instance.map_resource_to_data['data']).to_not include('startDate')
    end

    specify do
      resource[:start_time] = :absent

      expect(instance.map_resource_to_data['data']).to_not include('startTime')
    end

    specify do
      resource[:start_time] = '1:23'

      expect(instance.map_resource_to_data['data']).to include('startTime' => '1:23')
    end

    specify do
      resource[:recurring_day] = 'sunday'

      expect(instance.map_resource_to_data['data']).to include('recurringDay' => ['sunday'])
    end

    specify do
      resource[:recurring_day] = :absent

      expect(instance.map_resource_to_data['data']).to_not include('recurringDay')
    end

    specify do
      resource[:recurring_time] = '21:31'

      expect(instance.map_resource_to_data['data']).to include('recurringTime' => '21:31')
    end

    specify do
      resource[:recurring_time] = :absent

      expect(instance.map_resource_to_data['data']).to_not include('recurringTime')
    end

    specify do
      resource[:cron_expression] = :absent

      expect(instance.map_resource_to_data['data']).to_not include('cronCommand')
    end

    specify do
      resource[:cron_expression] = '0 0 12 * * ?'

      expect(instance.map_resource_to_data['data']).to include('cronCommand' => '0 0 12 * * ?')
    end
  end

  describe :destroy do
    specify 'should use /service/local/repositories/schedules to delete an existing resource' do
      resource[:id] = 'a1b2'
      Nexus::Rest.should_receive(:destroy).with('/service/local/schedules/a1b2')

      expect { instance.destroy }.to_not raise_error
    end

    specify 'should raise a human readable error message if the operation failed' do
      Nexus::Rest.should_receive(:destroy).and_raise('Operation failed')

      expect { instance.destroy }.to raise_error(Puppet::Error, /Error while deleting Nexus_scheduled_task\['Empty Trash'\]/)
    end
  end
end
