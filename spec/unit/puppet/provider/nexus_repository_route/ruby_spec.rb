require 'spec_helper'

provider_class = Puppet::Type.type(:nexus_repository_route).provider(:ruby)

describe provider_class do
  before(:each) do
    Nexus::Config.stub(:resolve).and_return('http://example.com/foobar')
  end

  let :provider do
    resource = Puppet::Type::Nexus_repository_route.new({
      :title                   => 'example-route-1',
      :position                => '0',
      :id                      => '195adcafe5',
      :url_pattern             => '.*/com/atlassian/.*',
      :rule_type               => 'inclusive',
      :repository_group        => 'repo-group-1',
      :repositories            => ['repository-1', 'repository-2']
    })
    provider_class.new(resource)
  end

  describe 'an instance' do
    let :instance do
      Nexus::Rest.should_receive(:get_all).with('/service/local/repo_routes').and_return({
        'data' => [{
          'resourceURI'            => 'http://nexus-server.local/service/local/repo_routes/2badbeef5',
          'pattern'                => '.*/io/atlassian/.*',
          'ruleType'               => 'inclusive',
          'groupId'                => 'repo-group-2',
          'repositories'           => [{'id' => 'repository-3'}, {'id' => 'repository-4'}]
        }]
      })

      Nexus::Rest.should_receive(:get_all).with('/service/local/repo_routes/2badbeef5').and_return({
        'data' => {
          'id'                      => '2badbeef5',
          'pattern'                => '.*/io/atlassian/.*',
          'ruleType'               => 'inclusive',
          'groupId'                => 'repo-group-2',
          'repositories'           => [{'id' => 'repository-3'}, {'id' => 'repository-4'}]
        }
      })

      provider_class.instances[0]
    end

    it { expect(instance.name).to eq('0') }
    it { expect(instance.id).to eq('2badbeef5') }
    it { expect(instance.url_pattern).to eq('.*/io/atlassian/.*') }
    it { expect(instance.rule_type).to eq(:inclusive) }
    it { expect(instance.repository_group).to eq('repo-group-2') }
    it { expect(instance.repositories).to eq("repository-3,repository-4") }
  end

  describe 'create' do
    it 'should use /service/local/repo_routes' do
      Nexus::Rest.should_receive(:create).with('/service/local/repo_routes', anything())
      provider.create
    end
    it 'should raise a human readable error message if the operation failed' do
      Nexus::Rest.should_receive(:create).and_raise('Operation failed')
      expect { provider.create }.to raise_error(Puppet::Error, /Error while creating nexus_repository_route 0/)
    end
    it 'should map url_pattern to pattern' do
      Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:pattern => '.*/com/atlassian/.*'))
      provider.create
    end
    it 'should map rule_type to ruleType' do
      Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:ruleType => :inclusive))
      provider.create
    end
    it 'should map repository_group to groupId' do
      Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:groupId => 'repo-group-1'))
      provider.create
    end
    it 'should map repositories to repositories' do
      Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:repositories => [{'id' => 'repository-1'}, {'id' => 'repository-2'}]))
      provider.create
    end
  end

  describe 'flush' do
    before(:each) do
      # mark resources as 'dirty'
      provider.rule_type = :inclusive
      provider.instance_variable_get(:@property_hash)[:id] = '195adcafe5'
    end
    it 'should use /service/local/repo_groups/<repo_route_id>' do
      Nexus::Rest.should_receive(:update).with('/service/local/repo_routes/195adcafe5', anything())
      provider.flush
    end
    it 'should raise a human readable error message if the operation failed' do
      Nexus::Rest.should_receive(:update).and_raise('Operation failed')
      expect { provider.flush }.to raise_error(Puppet::Error, /Error while updating nexus_repository_route 0/)
    end
    it 'should map url_pattern to pattern' do
      Nexus::Rest.should_receive(:update).with(anything, :data => hash_including(:pattern =>  '.*/com/atlassian/.*'))
      provider.flush
    end
    it 'should map rule_type to ruleType' do
      Nexus::Rest.should_receive(:update).with(anything, :data => hash_including(:ruleType => :inclusive))
      provider.flush
    end
    it 'should map repository_group to groupId' do
      Nexus::Rest.should_receive(:update).with(anything, :data => hash_including(:groupId => 'repo-group-1'))
      provider.flush
    end
    it 'should map repositories to repositories' do
      Nexus::Rest.should_receive(:update).with(anything, :data => hash_including(:repositories => [{'id' => 'repository-1'}, {'id' => 'repository-2'}]))
      provider.flush
    end
  end

  describe 'destroy' do
    before(:each) do
      # mark resources as 'dirty'
      provider.instance_variable_get(:@property_hash)[:id] = '195adcafe5'
    end
    it 'should use /service/local/repo_routes/<repo_route_id>' do
      Nexus::Rest.should_receive(:destroy).with('/service/local/repo_routes/195adcafe5')
      provider.destroy
    end
    it 'should raise a human readable error message if the operation failed' do
      Nexus::Rest.should_receive(:destroy).and_raise('Operation failed')
      expect { provider.destroy }.to raise_error(Puppet::Error, /Error while deleting nexus_repository_route 0/)
    end
  end

  it "should return false if it is not existing" do
    # the dummy example isn't returned by self.instances
    expect(provider.exists?).to be_false
  end
end
