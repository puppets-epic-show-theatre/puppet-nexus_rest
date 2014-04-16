require 'spec_helper'

provider_class = Puppet::Type.type(:nexus_repository).provider(:ruby)

describe provider_class do
  before(:each) do
    Nexus::Config.stub(:resolve).and_return('http://example.com/foobar')
  end

  let :provider do
    resource = Puppet::Type::Nexus_repository.new({
      :name          => 'example',
      :label         => 'Example Repository',
      :provider_type => :maven2,
    })
    provider_class.new(resource)
  end

  describe 'instances' do
    let :instances do
      Nexus::Rest.should_receive(:get_all).with('/service/local/repositories').and_return({'data' => [{'id' => 'repository-1'}, {'id' => 'repository-2'}]})
      provider_class.instances
    end

    it { instances.should have(2).items }
  end

  describe 'instances' do
    it 'should raise a human readable error message if the operation failed' do
      Nexus::Rest.should_receive(:get_all).and_raise('Operation failed')
      expect { provider_class.instances }.to raise_error(Puppet::Error, /Error while retrieving all nexus_repository instances/)
    end
  end

  describe 'an instance' do
    let :instance do
      Nexus::Rest.should_receive(:get_all).with('/service/local/repositories').and_return({
        'data' => [{
          'id'       => 'repository-1',
          'name'     => 'repository name',
          'provider' => 'maven2',
        }]
      })
      provider_class.instances[0]
    end

    it { expect(instance.name).to eq('repository-1') }
    it { expect(instance.label).to eq('repository name') }
    it { expect(instance.provider_type).to eq('maven2') }
    it { expect(instance.exists?).to be_true }
  end

  describe 'create' do
    it 'should use /service/local/repositories to create a new resource' do
      Nexus::Rest.should_receive(:create).with('/service/local/repositories', anything())
      provider.create
    end
    it 'should raise a human readable error message if the operation failed' do
      Nexus::Rest.should_receive(:create).and_raise('Operation failed')
      expect { provider.create }.to raise_error(Puppet::Error, /Error while creating nexus_repository example/)
    end
    it 'should map name to id' do
      Nexus::Rest.should_receive(:create).with(anything(), :data => hash_including({:id => 'example'}))
      provider.create
    end
    it 'should map label to name' do
      Nexus::Rest.should_receive(:create).with(anything(), :data => hash_including({:name => 'Example Repository'}))
      provider.create
    end
    it 'should map provider_type to provider' do
      Nexus::Rest.should_receive(:create).with(anything(), :data => hash_including({:provider => :maven2}))
      provider.create
    end
  end

  describe 'update' do
    it 'should use /service/local/repositories/example to update an existing resource' do
      Nexus::Rest.should_receive(:update).with('/service/local/repositories/example')
      provider.update
    end
    it 'should raise a human readable error message if the operation failed' do
      Nexus::Rest.should_receive(:update).and_raise('Operation failed')
      expect { provider.update }.to raise_error(Puppet::Error, /Error while updating nexus_repository example/)
    end
  end

  describe 'destroy' do
    it 'should use /service/local/repositories/example to delete an existing resource' do
      Nexus::Rest.should_receive(:destroy).with('/service/local/repositories/example')
      provider.destroy
    end
    it 'should raise a human readable error message if the operation failed' do
      Nexus::Rest.should_receive(:destroy).and_raise('Operation failed')
      expect { provider.destroy }.to raise_error(Puppet::Error, /Error while deleting nexus_repository example/)
    end
  end

  it "should return false if it is not existing" do
    # the dummy example isn't returned by self.instances
    expect(provider.exists?).to be_false
  end
end
