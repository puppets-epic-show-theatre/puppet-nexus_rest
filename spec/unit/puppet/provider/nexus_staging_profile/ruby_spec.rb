require 'spec_helper'

describe Puppet::Type.type(:nexus_staging_profile).provider(:ruby) do
  let(:example_data) do
    {
        'id'                        => '1',
        'name'                      => 'example-profile',
        'repositoryTemplateId'      => 'my-template-id',
        'repositoryType'            => 'typeX',
        'promotionTargetRepository' => 'my-release-repository-id',
        'repositoriesSearchable'    => false,
        'finishNotifyEmails'        => 'finish@example.com',
        'finishNotifyRoles'         => ['role-a'],
        'finishNotifyCreator'       => true,
        'promoteNotifyEmails'       => 'drop@example.com',
        'promotionNotifyRoles'      => ['role-b'],
        'promotionNotifyCreator'    => true,
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
    Nexus::Config.stub(:can_delete_repositories).and_return(true)
    Nexus::Rest.stub(:get_all).and_return({'data' => {'otherdata' => 'foobar'}})
    described_class.stub(:get_known_rulesets).and_return({'beef-1' => 'ruleset-1', 'beef-2' => 'ruleset-2'})
  end

  describe :instances do
    specify do
      Nexus::Rest.should_receive(:get_all).with('/service/local/staging/profiles').and_return(
          {
              'data' => [
                  {
                      'id'                        => '1',
                      'name'                      => 'profile 1',
                      'repositoryTargetId'        => 'all artifacts',
                      'promotionTargetRepository' => 'public artifacts',
                      'targetGroups'              => [
                          'public repositories'
                      ]
                  },
                  {
                      'id'                        => '2',
                      'name'                      => 'profile 2',
                      'repositoryTargetId'        => 'internal artifacts',
                      'promotionTargetRepository' => 'internal artifacts repository',
                      'targetGroups'              => [
                          'internal repositories'
                      ]
                  }
              ]
          }
      )

      expect(described_class.instances).to have(2).items
    end

    specify do
      Nexus::Rest.should_receive(:get_all).and_raise('Operation failed')

      expect { described_class.instances }.to raise_error(Puppet::Error, /Error while retrieving all nexus_staging_profile instances/)
    end

    specify 'should set ensure to present' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data]})

      expect(described_class.instances[0].ensure).to eq(:present)
    end

    specify 'should retrieve id' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data]})

      expect(described_class.instances[0].id).to eq('1')
    end

    specify 'should retrieve name' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data]})

      expect(described_class.instances[0].name).to eq('example-profile')
    end

    specify 'should map autoStagingDisabled to implicitly_selectable' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data.merge('autoStagingDisabled' => true)]})

      expect(described_class.instances[0].implicitly_selectable).to eq(:false)
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

    specify 'should map repositoryType to repository_type' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data.merge('repositoryType' => 'typeX')]})

      expect(described_class.instances[0].repository_type).to eq('typeX')
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
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data.merge('finishNotifyEmails' => 'finish@example.com')]})

      expect(described_class.instances[0].close_notify_emails).to eq('finish@example.com')
    end

    specify 'should map finishNotifyRoles to close_notify_roles' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data.merge('finishNotifyRoles' => ['admins', 'users'])]})

      expect(described_class.instances[0].close_notify_roles).to eq('admins,users')
    end

    specify 'should map finishNotifyCreator to close_notify_creator' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data.merge('finishNotifyCreator' => true)]})

      expect(described_class.instances[0].close_notify_creator).to eq(:true)
    end

    specify 'should map closeRuleSets to close_rulesets and resolve ruleset ids to name' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data.merge('closeRuleSets' => ['beef-1'])]})

      expect(described_class.instances[0].close_rulesets).to eq('ruleset-1')
    end

    specify 'should map promotionNotifyEmails to promote_notify_emails' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data.merge('promotionNotifyEmails' => 'promote@example.com')]})

      expect(described_class.instances[0].promote_notify_emails).to eq('promote@example.com')
    end

    specify 'should map promotionNotifyRoles to promote_notify_roles' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data.merge('promotionNotifyRoles' => ['admins', 'users'])]})

      expect(described_class.instances[0].promote_notify_roles).to eq('admins,users')
    end

    specify 'should map promotionNotifyCreator to promote_notify_creator' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data.merge('promotionNotifyCreator' => true)]})

      expect(described_class.instances[0].promote_notify_creator).to eq(:true)
    end

    specify 'should map promoteRuleSets to promote_rulesets' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data.merge('promoteRuleSets' => ['beef-2'])]})

      expect(described_class.instances[0].promote_rulesets).to eq('ruleset-2')
    end

    specify 'should map dropNotifyEmails to drop_notify_emails' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data.merge('dropNotifyEmails' => 'drop@example.com')]})

      expect(described_class.instances[0].drop_notify_emails).to eq('drop@example.com')
    end

    specify 'should map dropNotifyRoles to drop_notify_roles' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data.merge('dropNotifyRoles' => ['admins', 'users'])]})

      expect(described_class.instances[0].drop_notify_roles).to eq('admins,users')
    end

    specify 'should map dropNotifyCreator to drop_notify_creator' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data.merge('dropNotifyCreator' => false)]})

      expect(described_class.instances[0].drop_notify_creator).to eq(:false)
    end
  end

  describe :create do
    specify 'should use /service/local/staging/profiles to create a new resource' do
      Nexus::Rest.should_receive(:create).with('/service/local/staging/profiles', anything())

      expect { instance.create }.to_not raise_error
    end

    specify 'should raise a human readable error message if the operation failed' do
      Nexus::Rest.should_receive(:create).and_raise('Operation failed')

      expect { instance.create }.to raise_error(Puppet::Error, /Error while creating nexus_staging_profile\['any'\]/)
    end
  end

  describe :map_resource_to_data do
    specify 'should map implicitly_selectable to autoStagingDisabled' do
      resource[:implicitly_selectable] = :false

      expect(instance.map_resource_to_data['data']).to include('autoStagingDisabled' => true)
    end

    specify 'should map searchable to repositoriesSearchable' do
      resource[:searchable] = 'true'

      expect(instance.map_resource_to_data['data']).to include('repositoriesSearchable' => true)
    end

    specify 'should map staging_mode `both` to `BOTH`' do
      resource[:staging_mode] = :both

      expect(instance.map_resource_to_data['data']).to include('mode' => 'BOTH')
    end

    specify 'should map staging_mode `deploy` to `DEPLOY`' do
      resource[:staging_mode] = :deploy

      expect(instance.map_resource_to_data['data']).to include('mode' => 'DEPLOY')
    end

    specify 'should map staging_mode `upload` to `UPLOAD`' do
      resource[:staging_mode] = :upload

      expect(instance.map_resource_to_data['data']).to include('mode' => 'UPLOAD')
    end

    specify 'should map staging_template to repositoryTemplateId' do
      resource[:staging_template] = 'template-id'

      expect(instance.map_resource_to_data['data']).to include('repositoryTemplateId' => 'template-id')
    end

    specify 'should map repository_type to repositoryType' do
      resource[:repository_type] = 'typeX'

      expect(instance.map_resource_to_data['data']).to include('repositoryType' => 'typeX')
    end

    specify 'should map repository_target to repositoryTargetId' do
      resource[:repository_target] = 'repository-target-name'

      expect(instance.map_resource_to_data['data']).to include('repositoryTargetId' => 'repository-target-name')
    end

    specify 'should map release_repository to promotionTargetRepository' do
      resource[:release_repository] = 'my-release-repository-id'

      expect(instance.map_resource_to_data['data']).to include('promotionTargetRepository' => 'my-release-repository-id')
    end

    specify 'should map close_notify_emails to finishNotifyEmails' do
      resource[:close_notify_emails] = 'close@example.com'

      expect(instance.map_resource_to_data['data']).to include('finishNotifyEmails' => 'close@example.com')
    end

    specify 'should map close_notify_roles to finishNotifyRoles' do
      resource[:close_notify_roles] = ['admins', 'users']

      expect(instance.map_resource_to_data['data']).to include('finishNotifyRoles' => ['admins', 'users'])
    end

    specify 'should map close_notify_creator to finishNotifyCreator' do
      resource[:close_notify_creator] = :true

      expect(instance.map_resource_to_data['data']).to include('finishNotifyCreator' => true)
    end

    specify 'should map close_rulesets to closeRuleSets' do
      resource[:close_rulesets] = ['ruleset-1', 'ruleset-2']

      expect(instance.map_resource_to_data['data']).to include('closeRuleSets' => ['beef-1', 'beef-2'])
    end

    specify 'should map promote_notify_emails to promotionNotifyEmails' do
      resource[:promote_notify_emails] = 'finish@example.com'

      expect(instance.map_resource_to_data['data']).to include('promotionNotifyEmails' => 'finish@example.com')
    end

    specify 'should map promote_notify_roles to promotionNotifyRoles' do
      resource[:promote_notify_roles] = ['admins', 'users']

      expect(instance.map_resource_to_data['data']).to include('promotionNotifyRoles' => ['admins', 'users'])
    end

    specify 'should map promote_notify_creator to promotionNotifyCreator' do
      resource[:promote_notify_creator] = :false

      expect(instance.map_resource_to_data['data']).to include('promotionNotifyCreator' => false)
    end

    specify 'should map promote_rulesets to promoteRuleSets' do
      resource[:promote_rulesets] = ['ruleset-1', 'ruleset-2']

      expect(instance.map_resource_to_data['data']).to include('promoteRuleSets' => ['beef-1', 'beef-2'])
    end

    specify 'should map drop_notify_emails to dropNotifyEmails' do
      resource[:drop_notify_emails] = 'drop@example.com'

      expect(instance.map_resource_to_data['data']).to include('dropNotifyEmails' => 'drop@example.com')
    end

    specify 'should map drop_notify_roles to dropNotifyRoles' do
      resource[:drop_notify_roles] = ['admins', 'users']

      expect(instance.map_resource_to_data['data']).to include('dropNotifyRoles' => ['admins', 'users'])
    end

    specify 'should map drop_notify_creator to dropNotifyCreator' do
      resource[:drop_notify_creator] = :false

      expect(instance.map_resource_to_data['data']).to include('dropNotifyCreator' => false)
    end
  end

  describe :flush do
    specify 'should use /service/local/staging/profiles/<id> to update an existing resource' do
      instance.set({:id => 'a1b2'})
      instance.mark_config_dirty
      Nexus::Rest.should_receive(:update).with('/service/local/staging/profiles/a1b2', anything())

      expect { instance.flush }.to_not raise_error
    end

    specify 'should raise a human readable error message if the operation failed' do
      instance.mark_config_dirty
      Nexus::Rest.should_receive(:update).and_raise('Operation failed')

      expect { instance.flush }.to raise_error(Puppet::Error, /Error while updating nexus_staging_profile\['any'\]/)
    end
  end

  describe :destroy do
    specify 'should use /service/local/staging/profiles/<id> to delete an existing resource' do
      instance.set({:id => 'a1b2'})
      Nexus::Rest.should_receive(:destroy).with('/service/local/staging/profiles/a1b2')

      expect { instance.destroy }.to_not raise_error
    end

    specify 'should raise a human readable error message if the operation failed' do
      Nexus::Rest.should_receive(:destroy).and_raise('Operation failed')

      expect { instance.destroy }.to raise_error(Puppet::Error, /Error while deleting nexus_staging_profile\['any'\]/)
    end

    specify 'should fail if configuration prevents deletion of staging profiles' do
      Nexus::Config.stub(:can_delete_repositories).and_return(false)

      expect { instance.destroy }.to raise_error(RuntimeError, /current configuration prevents the deletion of nexus_staging_profile\['any'\]/)
    end

  end
end
