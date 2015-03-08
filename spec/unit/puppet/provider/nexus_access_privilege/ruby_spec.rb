require 'spec_helper'
require 'yaml'

provider_class = Puppet::Type.type(:nexus_access_privilege).provider(:ruby)

POST_FLUSH_RESPONSE =
  {'data' => [
    {
      'id' => 'id_1_1',
      'name' => 'name_1 - (read,create)',
      'description' => 'description_1',
      'type' => 'target',
      'userManaged' => true,
      'properties' => [
        { 'key' => 'repositoryGroupId', 'value' => '' },
        { 'key' => 'method', 'value' => 'read,create' },
        { 'key' => 'repositoryId', 'value' => 'repository_1' },
        { 'key' => 'repositoryTargetId', 'value' => 'repository_target_1' }
      ]
    },
    {
      'id' => 'id_0',
      'name' => 'name_0 - (update,delete)',
      'description' => 'description_0',
      'type' => 'target',
      'userManaged' => true,
      'properties' => [
        { 'key' => 'repositoryGroupId', 'value' => '' },
        { 'key' => 'method', 'value' => 'update,delete' },
        { 'key' => 'repositoryId', 'value' => 'repository_0' },
        { 'key' => 'repositoryTargetId', 'value' => 'repository_target_0' }
      ]
    }
  ]}

describe provider_class do
  before(:each) do
    Nexus::Config.stub(:resolve).and_return('http://example.com/foobar')
  end

  let :instance do
    resource = Puppet::Type::Nexus_access_privilege.new({
      :id                => 'id_1',
      :name              => 'name_1',
      :description       => 'description_1',
      :methods           => ['read', 'create'],
      :repository_target => 'repository_target_1',
      :repository        => 'repository_1'
    })
    provider_class.new(resource)
  end


  describe 'instances' do
    let :instances do
      Nexus::Rest.should_receive(:get_all).with('/service/local/privileges').and_return(
        {'data' => [
          {
            'id' => 'id_2',
            'name' => 'name_2 - (read,create,update)',
            'description' => 'description_2',
            'type' => 'target',
            'userManaged' => true,
            'properties' => [
              { 'key' => 'repositoryGroupId', 'value' => '' },
              { 'key' => 'method', 'value' => 'read,create,update' },
              { 'key' => 'repositoryId', 'value' => 'repository_2' },
              { 'key' => 'repositoryTargetId', 'value' => 'repository_target_2' }
            ]
          },
          {
            'id' => 'id_3',
            'name' => 'name_3 - (read,delete)',
            'description' => 'description_3',
            'type' => 'target',
            'userManaged' => true,
            'properties' => [
              { 'key' => 'repositoryGroupId', 'value' => 'repository_group_3' },
              { 'key' => 'method', 'value' => 'read,delete' },
              { 'key' => 'repositoryId', 'value' => '' },
              { 'key' => 'repositoryTargetId', 'value' => 'repository_target_3' }
            ]
          },
          {
            'userManaged' => false,
          },
        ]}
      )
      provider_class.instances
    end

    it { instances.should have(2).items }
  end

  describe 'instances' do
    it 'should raise a human readable error message if the operation failed' do
      Nexus::Rest.should_receive(:get_all).and_raise('Operation failed')
      expect { provider_class.instances }.to raise_error(Puppet::Error, /Error while retrieving all nexus_access_privilege instances/)
    end
  end

  describe 'an instance' do
    let :instance do
      Nexus::Rest.should_receive(:get_all).with('/service/local/privileges').and_return({
        'data' => [
          {
            'id' => 'id_4',
            'name' => 'name_4 - (read,create,update)',
            'description' => 'description_4',
            'type' => 'target',
            'userManaged' => true,
            'properties' => [
              {
                'key' => 'repositoryGroupId',
                'value' => ''
              },
              {
                'key' => 'method',
                'value' => 'read,create,update'
              },
              {
                'key' => 'repositoryId',
                'value' => 'repository_4'
              },
              {
                'key' => 'repositoryTargetId',
                'value' => 'repository_target_4'
              }
            ]
          }
        ]
      })
      provider_class.instances[0]
    end

    it { expect(instance.id).to eq('id_4') }
    it { expect(instance.name).to eq('name_4') }
    it { expect(instance.description).to eq('description_4') }
    it { expect(instance.methods).to eq(['read', 'create', 'update']) }
    it { expect(instance.repository_target).to eq('repository_target_4') }
    it { expect(instance.repository).to eq('repository_4') }
  end

  describe 'create' do
    it 'should use /service/local/privileges_target to create a new resource' do
      Nexus::Rest.should_receive(:create).with('/service/local/privileges_target', anything())
      instance.create
    end
    it 'should raise a human readable error message if the operation failed' do
      Nexus::Rest.should_receive(:create).and_raise('Operation failed')
      expect { instance.create }.to raise_error(Puppet::Error, /Error while creating nexus_access_privilege name_1/)
    end
    it 'should map name to name' do
      Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:name => 'name_1'))
      instance.create
    end
    it 'should map description to description' do
      Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:description => 'description_1'))
      instance.create
    end
    it 'should map methods to method' do
      Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:method => ['read,create']))
      instance.create
    end
    it 'should map repository_target to repositoryTargetId' do
      Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:repositoryTargetId => 'repository_target_1'))
      instance.create
    end
    it 'should map repository to repositoryId' do
      Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:repositoryId => 'repository_1'))
      instance.create
    end
    it 'should map repository_group to repositoryGroupId' do
      Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:repositoryGroupId => ''))
      instance.create
    end
  end

  describe 'destroy' do
    before(:each) do
      #set id in property hash
      instance.instance_variable_get(:@property_hash)[:id] = 'id_1'
    end
    it 'should use /service/local/privileges/<privilege_id> to delete an existing resource' do
      Nexus::Rest.should_receive(:destroy).with('/service/local/privileges/id_1')
      instance.destroy
    end
    it 'should raise a human readable error message if the operation failed' do
      Nexus::Rest.should_receive(:destroy).and_raise('Operation failed')
      expect { instance.destroy }.to raise_error(Puppet::Error, /Error while deleting nexus_access_privilege name_1/)
    end
  end
  it "should return false if it is not existing" do
    # the dummy example isn't returned by self.instances
    expect(instance.exists?).to be_false
  end

  describe 'flush' do
    before(:each) do
      #mark resources as 'dirty' and reset id to pre-update state
      instance.mark_config_dirty
      instance.instance_variable_get(:@property_hash)[:id] = 'id_1'
    end
    it 'should delete using /service/local/privileges/<privilege_id> and create using /service/local/privileges_target to update an existing resource' do
      Nexus::Rest.should_receive(:destroy).with('/service/local/privileges/id_1')
      Nexus::Rest.should_receive(:create).with('/service/local/privileges_target', anything())
      Nexus::Rest.should_receive(:get_all).with('/service/local/privileges').and_return(POST_FLUSH_RESPONSE)
      instance.flush
      expect(instance.instance_variable_get(:@property_hash)[:id]).to eq('id_1_1')
    end
    it 'should raise a human readable error message if the operation failed' do
      Nexus::Rest.should_receive(:destroy).and_raise('Operation failed')
      expect { instance.flush }.to raise_error(Puppet::Error, /Error while updating nexus_access_privilege name_1/)
    end
  end
end
