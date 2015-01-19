require 'spec_helper'

provider_class = Puppet::Type.type(:nexus_repository_target).provider(:ruby)

describe provider_class do
  before(:each) do
    Nexus::Config.stub(:resolve).and_return('http://example.com/foobar')
  end

  let :provider do
    resource = Puppet::Type::Nexus_repository_target.new({
      :name                    => 'example-target-1',
      :label                   => 'Example Repository Target 1',
      :provider_type           => 'maven2',
      :patterns                => ['^/com/atlassian/.*$', '^/io/atlassian/.*$']
    })
    provider_class.new(resource)
  end

  describe 'instances' do
    let :instances do
      Nexus::Rest.should_receive(:get_all).with('/service/local/repo_targets').and_return(
        {'data' => [
          {'id'               => 'example-target-2',
           'name'             => 'Example Repository Target 2',
           'contentClass'     => 'all',
           'patterns'         => ['.*things.*', '.*stuff.*'],
          },
          {'id'               => 'example-target-3',
           'name'             => 'Example Repository Target 3',
           'contentClass'     => 'maven1',
           'patterns'         => ['.*gubbins.*', '.*kit.*'],
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
      expect { provider_class.instances }.to raise_error(Puppet::Error, /Error while retrieving all nexus_repository_target instances/)
    end
  end

  describe 'an instance' do
    let :instance do
      Nexus::Rest.should_receive(:get_all).with('/service/local/repo_targets').and_return({
        'data' => [
          {'id'               => 'example-target-4',
           'name'             => 'Example Repository Target 4',
           'contentClass'     => 'site',
           'patterns'         => ['.*paraphernalia.*', '.*trappings.*'],
          }]
      })
      provider_class.instances[0]
    end

    it { expect(instance.name).to eq('example-target-4') }
    it { expect(instance.label).to eq('Example Repository Target 4') }
    it { expect(instance.provider_type).to eq('site') }
    it { expect(instance.patterns).to eq(['.*paraphernalia.*', '.*trappings.*']) }
  end

  describe 'create' do
    it 'should use /service/local/repo_targets to create a new resource' do
      Nexus::Rest.should_receive(:create).with('/service/local/repo_targets', anything())
      provider.create
    end
    it 'should raise a human readable error message if the operation failed' do
      Nexus::Rest.should_receive(:create).and_raise('Operation failed')
      expect { provider.create }.to raise_error(Puppet::Error, /Error while creating nexus_repository_target example/)
    end
    it 'should map name to id' do
      Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:id => 'example-target-1'))
      provider.create
    end
    it 'should map label to name' do
      Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:name => 'Example Repository Target 1'))
      provider.create
    end
    it 'should map provider_type to contentClass' do
      Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:contentClass => 'maven2'))
      provider.create
    end
    it 'should map patterns to patterns' do
      Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:patterns => ['^/com/atlassian/.*$', '^/io/atlassian/.*$']))
      provider.create
    end

  end

  describe 'flush' do
    before(:each) do
      # mark resources as 'dirty'
      provider.provider_type = :maven2
    end
    it 'should use /service/local/repo_targets/example-target-1 to update an existing resource' do
      Nexus::Rest.should_receive(:update).with('/service/local/repo_targets/example-target-1', anything())
      provider.flush
    end
    it 'should raise a human readable error message if the operation failed' do
      Nexus::Rest.should_receive(:update).and_raise('Operation failed')
      expect { provider.flush }.to raise_error(Puppet::Error, /Error while updating nexus_repository_target example/)
    end
    it 'should map name to id' do
      Nexus::Rest.should_receive(:update).with(anything, :data => hash_including(:id => 'example-target-1'))
      provider.flush
    end
    it 'should map label to name' do
      Nexus::Rest.should_receive(:update).with(anything, :data => hash_including(:name => 'Example Repository Target 1'))
      provider.flush
    end
    it 'should map provider_type to contentClass' do
      Nexus::Rest.should_receive(:update).with(anything, :data => hash_including(:contentClass => 'maven2'))
      provider.flush
    end
    it 'should map patterns to patterns' do
      Nexus::Rest.should_receive(:update).with(anything, :data => hash_including(:patterns => ['^/com/atlassian/.*$', '^/io/atlassian/.*$']))
      provider.flush
    end
  end

  describe 'destroy' do
    it 'should use /service/local/repo_targets/example-target-1 to delete an existing resource' do
      Nexus::Rest.should_receive(:destroy).with('/service/local/repo_targets/example-target-1')
      provider.destroy
    end
    it 'should raise a human readable error message if the operation failed' do
      Nexus::Rest.should_receive(:destroy).and_raise('Operation failed')
      expect { provider.destroy }.to raise_error(Puppet::Error, /Error while deleting nexus_repository_target example-target-1/)
    end
  end

  it "should return false if it is not existing" do
    # the dummy example isn't returned by self.instances
    expect(provider.exists?).to be_false
  end
end
