require 'spec_helper'

describe Puppet::Type.type(:nexus_staging_profile).provider(:ruby) do
  let(:example_data) do
    {
        'id'                        => '1',
        'repositoryTemplateId'      => 'my-template-id',
        'promotionTargetRepository' => 'my-release-repository-id',
        'repositoriesSearchable'    => false,
        'finishNotifyEmails'        => 'finish@example.com',
        'finishNotifyRoles'         => ['role-a'],
        'finishNotifyCreator'       => true,
        'promoteNotifyEmails'       => 'drop@example.com',
        'promoteNotifyRoles'        => ['role-b'],
        'promoteNotifyCreator'      => true,
        'dropNotifyEmails'          => 'drop@example.com',
        'dropNotifyRoles'           => [],
        'dropNotifyCreator'         => false,
        'closeRuleSets'             => ['ruleset-1'],
        'promoteRuleSets'           => ['ruleset-2']
    }
  end

  let(:resource) do
    {
        :name               => 'any',
        :repository_target  => 'repository-target',
        :release_repository => 'Public artifacts',
        :target_groups      => 'Public repositories'
    }
  end

  let(:instance) do
    described_class.new(Puppet::Type::Nexus_staging_profile.new(resource))
  end

  before(:each) do
    Nexus::Config.stub(:resolve).and_return('http://example.com/foobar')
    Nexus::Rest.stub(:get_all).and_return({'data' => {'otherdata' => 'foobar'}})
  end

  describe :instances do
    specify 'should map autoStagingDisabled to implicitly_selectable' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data.merge('autoStagingDisabled' => true)]})

      expect(described_class.instances[0].implicitly_selectable).to eq(:true)
    end

    specify 'should map repositoriesSearchable to searchable' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data]})

      expect(described_class.instances[0].searchable).to eq(:false)
    end

    specify 'should map mode `BOTH` to `both`' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data.merge('mode' => 'BOTH')]})

      expect(described_class.instances[0].staging_mode).to eq(:both)
    end

    specify 'should map mode `DEPLOY` to `deploy`' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data.merge('mode' => 'DEPLOY')]})

      expect(described_class.instances[0].staging_mode).to eq(:deploy)
    end

    specify 'should map mode `UPLOAD` to `upload`' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data.merge('mode' => 'UPLOAD')]})

      expect(described_class.instances[0].staging_mode).to eq(:upload)
    end

    specify 'should map repositoryTemplateId to staging_template' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data.merge('repositoryTemplateId' => 'my-template')]})

      expect(described_class.instances[0].staging_template).to eq('my-template')
    end

    specify 'should map repositoryTargetId to repository_target' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data.merge('repositoryTargetId' => 'repository-target-id')]})

      expect(described_class.instances[0].repository_target).to eq('repository-target-id')
    end

    specify 'should map promotionTargetRepository to release_repository' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data.merge('promotionTargetRepository' => 'my-repository-id')]})

      expect(described_class.instances[0].release_repository).to eq('my-repository-id')
    end

    specify 'should map finishNotifyEmails to close_notify_emails' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data.merge('finishNotifyEmails' => 'close@example.com')]})

      expect(described_class.instances[0].close_notify_emails).to eq('close@example.com')
    end

    specify 'should map finishNotifyRoles to close_notify_roles' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data.merge('finishNotifyRoles' => ['admins', 'users'])]})

      expect(described_class.instances[0].close_notify_roles).to eq('admins,users')
    end

    specify 'should map finishNotifyCreator to close_notify_creator' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data.merge('finishNotifyCreator' => true)]})

      expect(described_class.instances[0].close_notify_creator).to eq(:true)
    end

    specify 'should map closeRuleSets to close_rulesets' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data.merge('closeRuleSets' => ['ruleset-1'])]})

      expect(described_class.instances[0].close_rulesets).to eq('ruleset-1')
    end

    specify 'should map promotionNotifyEmails to promote_notify_emails' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data.merge('promotionNotifyEmails' => 'promote@example.com')]})

      expect(described_class.instances[0].promote_notify_emails).to eq('finish@example.com')
    end

    specify 'should map promoteNotifyRoles to promte_notify_roles' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data.merge('promoteNotifyRoles' => ['admins', 'users'])]})

      expect(described_class.instances[0].promte_notify_roles).to eq('admins,users')
    end

    specify 'should map promoteNotifyCreator to promote_notify_creator' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data.merge('promoteNotifyCreator' => true)]})

      expect(described_class.instances[0].promote_notify_creator).to eq(:true)
    end

    specify 'should map promoteRuleSets to promote_rulesets' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data.merge('promoteRuleSets' => ['ruleset-2'])]})

      expect(described_class.instances[0].promote_rulesets).to eq('ruleset-2')
    end

    specify 'should map dropNotifyEmails to drop_notify_emails' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data.merge('dropNotifyEmails' => 'drop@example.com')]})

      expect(described_class.instances[0].close_notify_emails).to eq('drop@example.com')
    end

    specify 'should map dropNotifyRoles to drop_notify_roles' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data.merge('dropNotifyRoles' => ['admins', 'users'])]})

      expect(described_class.instances[0].drop_notify_roles).to eq('admins,users')
    end

    specify 'should map dropNotifyCreator to ondrop_notify_creator' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data.merge('dropNotifyCreator' => false)]})

      expect(described_class.instances[0].ondrop_notify_creator).to eq(:false)
    end
  end

  describe :map_resource_to_data do
    specify 'should map implicitly_selectable to autoStagingDisabled' do
      resource[:implicitly_selectable] = :true

      expect(instance.map_resource_to_data['data'][0]).to include('autoStagingDisabled' => true)
    end

    specify 'should map searchable to repositoriesSearchable' do
      resource[:searchable] = 'true'

      expect(instance.map_resource_to_data['data'][0]).to include('repositoriesSearchable' => true)
    end

    specify 'should map staging_mode `both` to `BOTH`' do
      resource[:staging_mode] = :both

      expect(instance.map_resource_to_data['data'][0]).to include('mode' => 'BOTH')
    end

    specify 'should map staging_mode `deploy` to `DEPLOY`' do
      resource[:staging_mode] = :deploy

      expect(instance.map_resource_to_data['data'][0]).to include('mode' => 'DEPLOY')
    end

    specify 'should map staging_mode `upload` to `UPLOAD`' do
      resource[:staging_mode] = :upload

      expect(instance.map_resource_to_data['data'][0]).to include('mode' => 'UPLOAD')
    end

    specify 'should map staging_template to repositoryTemplateId' do
      resource[:staging_template] = 'template-id'

      expect(instance.map_resource_to_data['data'][0]).to include('repositoryTemplateId' => 'template-id')
    end

    specify 'should map repository_target to repositoryTargetId' do
      resource[:repository_target] = 'repository-target-name'

      expect(instance.map_resource_to_data['data'][0]).to include('repositoryTargetId' => 'repository-target-name')
    end

    specify 'should map release_repository to promotionTargetRepository' do
      resource[:release_repository] = 'my-release-repository-id'

      expect(instance.map_resource_to_data['data'][0]).to include('promotionTargetRepository' => 'my-release-repository-id')
    end

    specify 'should map close_notify_emails to finishNotifyEmails' do
      resource[:close_notify_emails] = 'close@example.com'

      expect(instance.map_resource_to_data['data'][0]).to include('finishNotifyEmails' => 'close@example.com')
    end

    specify 'should omit empty close_notify_emails' do
      resource[:close_notify_emails] = ''

      expect(instance.map_resource_to_data['data'][0]).to_not include('finishNotifyEmails')
    end

    specify 'should map close_notify_roles to finishNotifyRoles' do
      resource[:close_notify_roles] = 'admins,users'

      expect(instance.map_resource_to_data['data'][0]).to include('finishNotifyRoles' => ['admins', 'users'])
    end

    specify 'should map close_notify_creator to finishNotifyCreator' do
      resource[:close_notify_creator] = :true

      expect(instance.map_resource_to_data['data'][0]).to include('finishNotifyCreator' => true)
    end

    specify 'should map close_rulesets to closeRuleSets' do
      resource[:close_rulesets] = 'ruleset-1,ruleset-2'

      expect(instance.map_resource_to_data['data'][0]).to include('closeRuleSets' => ['ruleset-1', 'ruleset-2'])
    end

    specify 'should map promote_notify_emails to promotionNotifyEmails' do
      resource[:promote_notify_emails] = 'finish@example.com'

      expect(instance.map_resource_to_data['data'][0]).to include('promotionNotifyEmails' => 'finish@example.com')
    end

    specify 'should omit empty promote_notify_emails' do
      resource[:promote_notify_emails] = ''

      expect(instance.map_resource_to_data['data'][0]).to_not include('promotionNotifyEmails')
    end

    specify 'should map promote_notify_roles to promoteNotifyRoles' do
      resource[:promote_notify_roles] = 'admins,users'

      expect(instance.map_resource_to_data['data'][0]).to include('promoteNotifyRoles' => ['admins', 'users'])
    end

    specify 'should map promote_notify_creator to promoteNotifyCreator' do
      resource[:promote_notify_creator] = :false

      expect(instance.map_resource_to_data['data'][0]).to include('promoteNotifyCreator' => false)
    end

    specify 'should map promote_rulesets to promoteRuleSets' do
      resource[:promote_rulesets] = 'ruleset-1,ruleset-2'

      expect(instance.map_resource_to_data['data'][0]).to include('promoteRuleSets' => ['ruleset-1', 'ruleset-2'])
    end

    specify 'should map drop_notify_emails to dropNotifyEmails' do
      resource[:drop_notify_emails] = 'drop@example.com'

      expect(instance.map_resource_to_data['data'][0]).to include('dropNotifyEmails' => 'drop@example.com')
    end

    specify 'should omit empty promote_notify_emails' do
      resource[:drop_notify_emails] = ''

      expect(instance.map_resource_to_data['data'][0]).to_not include('dropNotifyEmails')
    end

    specify 'should map drop_notify_roles to dropNotifyRoles' do
      resource[:drop_notify_roles] = 'admins,users'

      expect(instance.map_resource_to_data['data'][0]).to include('dropNotifyRoles' => ['admins', 'users'])
    end

    specify 'should map drop_notify_creator to dropNotifyCreator' do
      resource[:drop_notify_creator] = :false

      expect(instance.map_resource_to_data['data'][0]).to include('dropNotifyCreator' => false)
    end
  end
end
