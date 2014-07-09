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
end
