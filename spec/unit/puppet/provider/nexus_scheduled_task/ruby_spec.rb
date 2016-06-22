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

  let(:release_staging_repositories) do
    {
      'id'         => '2',
      'name'       => 'Releasing staging repositories',
      'enabled'    => true,
      'typeId'     => 'ReleaseRemoverTask',
      'schedule'   => 'internal',
    }
  end

  let(:resource) do
    {
      :name            => 'Empty Trash',
      :enabled         => :true,
      :type            => 'Empty Trash',
      :reoccurrence    => :manual,
      :task_settings   => {
        'EmptyTrashItemsOlderThan' => '',
        'repositoryId'             => 'all_repo'
      }
    }
  end

  let(:instance) do
    described_class.new(Puppet::Type::Nexus_scheduled_task.new(resource))
  end

  before(:each) do
    Nexus::Config.stub(:resolve).and_return('http://example.com/foobar')
    Nexus::Rest.stub(:get_all).and_return({'data' => {'otherdata' => 'foobar'}})
    described_class.reset_do_not_touch
  end

  describe :instances do
    specify do
      Nexus::Rest.should_receive(:get_all_plus_n).with('/service/local/schedules').and_return(
        {
          'data' => [
            {
              'id'   => '1',
              'name' => 'task 1'
            },
            {
              'id'   => '2',
              'name' => 'task 2'
            }
          ]
        }
      )

      expect(described_class.instances).to have(2).items
    end

    specify 'should not accept duplicate items' do
      Nexus::Rest.should_receive(:get_all_plus_n).with('/service/local/schedules').and_return(
        {
          'data' => [
            {
              'id'   => '20',
              'name' => 'duplicate'
            },
            {
              'id'   => '9',
              'name' => 'duplicate'
            }
          ]
        }
      )

      expect { described_class.instances }.to raise_error(Puppet::Error, /Found multiple scheduled tasks with the same name 'duplicate'/)
      expect { described_class.do_not_touch.to equal(true) }
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

    specify 'should map typeId to type' do
      Nexus::Rest.should_receive(:get_all_plus_n).and_return({'data' => [empty_trash_task_details]})

      expect(described_class.instances[0].type).to eq('Empty Trash')
    end

    specify 'should map absent alert_email to empty string' do
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

      expect(described_class.instances[0].task_settings).to eq({
        'EmptyTrashItemsOlderThan' => '',
        'repositoryId'             => 'all_repo'
      })
    end

    specify 'should map absent start_date to :absent' do
      Nexus::Rest.should_receive(:get_all_plus_n).and_return({'data' => [empty_trash_task_details]})

      expect(described_class.instances[0].start_date).to be(:absent)
    end

    specify 'should map startDate to start_date' do
      # 1402790400000 is Sunday, June 15, 2014 12:00:00 AM GMT
      Nexus::Rest.should_receive(:get_all_plus_n).and_return({'data' => [empty_trash_task_details.merge('startDate' => '1402790400000')]})

      expect(described_class.instances[0].start_date).to eq('2014-06-15')
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

  describe :internal do
    specify 'should set ensure to present' do
      Nexus::Rest.should_receive(:get_all_plus_n).and_return({'data' => [release_staging_repositories]})

      expect(described_class.instances).to be_empty
    end
  end

  describe :create do
    specify 'should use /service/local/schedules to create a new resource' do
      Nexus::Rest.should_receive(:create).with('/service/local/schedules', anything())

      expect { instance.create }.to_not raise_error
    end

    specify 'should raise a human readable error message if the operation failed' do
      Nexus::Rest.should_receive(:create).and_raise('Operation failed')

      expect { instance.create }.to raise_error(Puppet::Error, /Error while creating nexus_scheduled_task\['Empty Trash'\]/)
    end
  end

  describe :map_resource_to_data do
    specify 'should return all changes within data hash' do
      expect(instance.map_resource_to_data.keys).to eq(['data'])
    end

    specify do
      expect(instance.map_resource_to_data['data']).to_not include('id')
    end

    specify do
      instance.set({:id => 'a1b2'})

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
      resource[:type] = 'Empty Trash'

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
      resource[:reoccurrence] = :manual

      expect(instance.map_resource_to_data['data']).to include('schedule' => 'manual')
    end

    specify do
      expect(instance.map_resource_to_data['data']).to include('properties' => [
        {'key'=> 'EmptyTrashItemsOlderThan', 'value' => ''},
        {'key' => 'repositoryId', 'value' => 'all_repo'}
      ])
    end

    specify do
      resource[:reoccurrence] = :once
      resource[:start_date] = '2014-06-15'
      resource[:start_time] = '10:00'

      # 1402790400000 is Sunday, June 15, 2014 12:00:00 AM GMT
      expect(instance.map_resource_to_data['data']).to include('startDate' => '1402790400000')
    end

    specify do
      resource.delete(:start_date)

      expect(instance.map_resource_to_data['data']).to_not include('startDate')
    end

    specify do
      resource.delete(:start_time)

      expect(instance.map_resource_to_data['data']).to_not include('startTime')
    end

    specify do
      resource[:reoccurrence] = :once
      resource[:start_date] = '2014-06-15'
      resource[:start_time] = '1:23'

      expect(instance.map_resource_to_data['data']).to include('startTime' => '1:23')
    end

    specify do
      resource[:reoccurrence] = :weekly
      resource[:start_date] = '2014-06-01'
      resource[:recurring_day] = 'sunday'
      resource[:recurring_time] = '21:31'

      expect(instance.map_resource_to_data['data']).to include('recurringDay' => ['sunday'])
    end

    specify do
      resource.delete(:recurring_day)

      expect(instance.map_resource_to_data['data']).to_not include('recurringDay')
    end

    specify do
      resource[:reoccurrence] = :daily
      resource[:start_date] = '2014-06-01'
      resource[:recurring_time] = '21:31'

      expect(instance.map_resource_to_data['data']).to include('recurringTime' => '21:31')
    end

    specify do
      resource.delete(:recurring_time)

      expect(instance.map_resource_to_data['data']).to_not include('recurringTime')
    end

    specify do
      resource.delete(:cron_expression)

      expect(instance.map_resource_to_data['data']).to_not include('cronCommand')
    end

    specify do
      resource[:reoccurrence] = :advanced
      resource[:cron_expression] = '0 0 12 * * ?'

      expect(instance.map_resource_to_data['data']).to include('cronCommand' => '0 0 12 * * ?')
    end
  end

  describe :flush do
    specify 'should use /service/local/schedules/<id> to update an existing resource' do
      instance.set({:id => 'a1b2'})
      instance.mark_config_dirty
      Nexus::Rest.should_receive(:update).with('/service/local/schedules/a1b2', anything())

      expect { instance.flush }.to_not raise_error
    end

    specify 'should raise a human readable error message if the operation failed' do
      instance.mark_config_dirty
      Nexus::Rest.should_receive(:update).and_raise('Operation failed')

      expect { instance.flush }.to raise_error(Puppet::Error, /Error while updating nexus_scheduled_task\['Empty Trash'\]/)
    end
  end

  describe :destroy do
    specify 'should use /service/local/repositories/schedules to delete an existing resource' do
      instance.set({:id => 'a1b2'})
      Nexus::Rest.should_receive(:destroy).with('/service/local/schedules/a1b2')

      expect { instance.destroy }.to_not raise_error
    end

    specify 'should raise a human readable error message if the operation failed' do
      Nexus::Rest.should_receive(:destroy).and_raise('Operation failed')

      expect { instance.destroy }.to raise_error(Puppet::Error, /Error while deleting nexus_scheduled_task\['Empty Trash'\]/)
    end
  end
end
