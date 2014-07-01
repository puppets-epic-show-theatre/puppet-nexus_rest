require 'spec_helper'

provider_class = Puppet::Type.type(:nexus_group_repository).provider(:ruby)

describe provider_class do
  before(:each) do
    Nexus::Config.stub(:resolve).and_return('http://example.com/foobar')
    Nexus::Config.stub(:can_delete_repositories).and_return(true)
  end

  let :provider do
    resource = Puppet::Type::Nexus_group_repository.new({
      :name                    => 'example-group',
      :label                   => 'Example Group Repository',
      :provider_type           => 'maven2',
      :exposed                 => :true,
      :repositories            => [['repository-1', 'repository-2']]
    })
    provider_class.new(resource)
  end

  describe 'an instance' do
    let :instance do
      Nexus::Rest.should_receive(:get_all).with('/service/local/repo_groups').and_return({
        'data' => [{
          'id'                      => 'example-group',
          'name'                    => 'Example Group Repository',
          'provider'                => 'maven2',
          'format'                  => 'maven2',
          'exposed'                 => true,
          'repositories'            => ['repository-1', 'repository-2']
        }]
      })
      provider_class.instances[0]
    end

    it { expect(instance.name).to eq('example-group') }
    it { expect(instance.label).to eq('Example Group Repository') }
    it { expect(instance.provider_type).to eq(:maven2) }
    it { expect(instance.exposed).to eq(:true) }
    it { expect(instance.repositories).to eq(['repository-1', 'repository-2']) }
    it { expect(instance.exists?).to be_true }
  end

  describe 'create' do
    it 'should use /service/local/repo_groups' do
      Nexus::Rest.should_receive(:create).with('/service/local/repo_groups', anything())
      provider.create
    end
    it 'should raise a human readable error message if the operation failed' do
      Nexus::Rest.should_receive(:create).and_raise('Operation failed')
      expect { provider.create }.to raise_error(Puppet::Error, /Error while creating nexus_group_repository example/)
    end
    it 'should map name to id' do
      Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:id => 'example-group'))
      provider.create
    end
    it 'should map label to name' do
      Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:name => 'Example Group Repository'))
      provider.create
    end
    it 'should map provider_type to provider' do
      Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:provider => :maven2))
      provider.create
    end
    it 'should map exposed symbol to boolean' do
      Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:exposed => true))
      provider.create
    end
    it 'should map repositories to repositories' do
      Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:repositories => ['repository-1', 'repository-2']))
      provider.create
    end
  end

  describe 'flush' do
    before(:each) do
      # mark resources as 'dirty'
      provider.exposed = :true
    end
    it 'should use /service/local/repo_groups/<repo_name>' do
      Nexus::Rest.should_receive(:update).with('/service/local/repo_groups/example-group', anything())
      provider.flush
    end
    it 'should raise a human readable error message if the operation failed' do
      Nexus::Rest.should_receive(:update).and_raise('Operation failed')
      expect { provider.flush }.to raise_error(Puppet::Error, /Error while updating nexus_group_repository example/)
    end
    it 'should map name to id' do
      Nexus::Rest.should_receive(:update).with(anything, :data => hash_including(:id => 'example-group'))
      provider.flush
    end
    it 'should map label to name' do
      Nexus::Rest.should_receive(:update).with(anything, :data => hash_including(:name => 'Example Group Repository'))
      provider.flush
    end
    it 'should map provider_type to provider' do
      Nexus::Rest.should_receive(:update).with(anything, :data => hash_including(:provider => :maven2))
      provider.flush
    end
    it 'should map provider_type to format' do
      Nexus::Rest.should_receive(:update).with(anything, :data => hash_including(:format => :maven2))
      provider.flush
    end
    it 'should map exposed symbol to boolean' do
      Nexus::Rest.should_receive(:update).with(anything, :data => hash_including(:exposed => true))
      provider.exposed = :true
      provider.flush
    end
    it 'should map repositories to repositories' do
      Nexus::Rest.should_receive(:update).with(anything, :data => hash_including(:repositories => ['repository-1', 'repository-2']))
      provider.repositories = ['repository-1', 'repository-2']
      provider.flush
    end
  end

  describe 'destroy' do
    it 'should use /service/local/repo_groups/<repo_name>' do
      Nexus::Rest.should_receive(:destroy).with('/service/local/repo_groups/example-group')
      provider.destroy
    end
    it 'should raise a human readable error message if the operation failed' do
      Nexus::Rest.should_receive(:destroy).and_raise('Operation failed')
      expect { provider.destroy }.to raise_error(Puppet::Error, /Error while deleting nexus_group_repository example-group/)
    end
    specify 'should fail if configuration prevents deletion of repositories' do
      Nexus::Config.stub(:can_delete_repositories).and_return(false)
      expect { provider.destroy }.to raise_error(RuntimeError, /current configuration prevents the deletion of nexus_group_repository example/)
    end
  end

  it "should return false if it is not existing" do
    # the dummy example isn't returned by self.instances
    expect(provider.exists?).to be_false
  end
end
