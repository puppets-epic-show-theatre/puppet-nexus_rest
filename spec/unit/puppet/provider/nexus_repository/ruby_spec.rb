require 'spec_helper'

provider_class = Puppet::Type.type(:nexus_repository).provider(:ruby)

describe provider_class do
  before(:each) do
    Nexus::Config.stub(:resolve).and_return('http://example.com/foobar')
  end

  let :provider do
    resource = Puppet::Type::Nexus_repository.new({
      :name                    => 'example',
      :label                   => 'Example Repository',
      :provider_type           => 'maven2',
      :type                    => 'hosted',
      :policy                  => 'SNAPSHOT',
      :exposed                 => :true,
      :write_policy            => :ALLOW_WRITE_ONCE,
      :browseable              => :true,
      :indexable               => :true,
      :not_found_cache_ttl     => 1440,
      :local_storage_url       => 'file:///some/path',
      :download_remote_indexes => :false
    })
    provider_class.new(resource)
  end

  describe 'instances' do
    let :instances do
      Nexus::Rest.should_receive(:get_all_plus_n).with('/service/local/repositories').and_return({'data' => [{'id' => 'repository-1'}, {'id' => 'repository-2'}]})
      provider_class.instances
    end

    it { instances.should have(2).items }
  end

  describe 'instances' do
    it 'should raise a human readable error message if the operation failed' do
      Nexus::Rest.should_receive(:get_all_plus_n).and_raise('Operation failed')
      expect { provider_class.instances }.to raise_error(Puppet::Error, /Error while retrieving all nexus_repository instances/)
    end
  end

  describe 'an instance' do
    let :instance do
      Nexus::Rest.should_receive(:get_all_plus_n).with('/service/local/repositories').and_return({
        'data' => [{
          'id'                      => 'repository-1',
          'name'                    => 'repository name',
          'provider'                => 'maven2',
          'format'                  => 'maven2',
          'repoType'                => 'hosted',
          'repoPolicy'              => 'SNAPSHOT',
          'exposed'                 => true,
          'writePolicy'             => 'ALLOW_WRITE_ONCE',
          'browseable'              => true,
          'indexable'               => true,
          'notFoundCacheTTL'        => 0,
          'overrideLocalStorageUrl' => 'file:///some/path',
          'downloadRemoteIndexes'   => false
        }]
      })
      provider_class.instances[0]
    end

    it { expect(instance.name).to eq('repository-1') }
    it { expect(instance.label).to eq('repository name') }
    it { expect(instance.provider_type).to eq('maven2') }
    it { expect(instance.type).to eq('hosted') }
    it { expect(instance.policy).to eq('SNAPSHOT') }
    it { expect(instance.exposed).to eq('true') }
    it { expect(instance.write_policy).to eq(:ALLOW_WRITE_ONCE) }
    it { expect(instance.browseable).to eq('true') }
    it { expect(instance.indexable).to eq('true') }
    it { expect(instance.not_found_cache_ttl).to eq(0) }
    it { expect(instance.local_storage_url).to eq('file:///some/path') }
    it { expect(instance.download_remote_indexes).to eq('false') }
    it { expect(instance.exists?).to be_true }
  end

  describe 'a nuget repository' do
    let :instance do
      Nexus::Rest.should_receive(:get_all_plus_n).with('/service/local/repositories').and_return({
        'data' => [{
          'id'                    => 'nuget-repository',
          'name'                  => 'repository name',
          'provider'              => 'nuget-proxy',
          'format'                => 'nuget',
          'repoType'              => 'hosted',
          'exposed'               => false,
          'writePolicy'           => 'READ_ONLY',
          'browseable'            => false,
          'indexable'             => false,
          'notFoundCacheTTL'      => 0,
          'downloadRemoteIndexes' => false,
        }]
      })
      provider_class.instances[0]
    end

    it { expect(instance.name).to eq('nuget-repository') }
    it { expect(instance.label).to eq('repository name') }
    it { expect(instance.provider_type).to eq('nuget') }
    it { expect(instance.type).to eq('hosted') }
    it { expect(instance.exposed).to eq('false') }
    it { expect(instance.write_policy).to eq(:READ_ONLY) }
    it { expect(instance.browseable).to eq('false') }
    it { expect(instance.indexable).to eq('false') }
    it { expect(instance.not_found_cache_ttl).to eq(0) }
    it { expect(instance.local_storage_url).to eq(:absent) }
    it { expect(instance.download_remote_indexes).to eq('false') }
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
      Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:id => 'example'))
      provider.create
    end
    it 'should map label to name' do
      Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:name => 'Example Repository'))
      provider.create
    end
    it 'should map provider_type to provider' do
      Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:provider => 'maven2'))
      provider.create
    end
    it 'should map type to repoType' do
      Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:repoType => 'hosted'))
      provider.create
    end
    it 'should map policy to repoPolicy' do
      Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:repoPolicy => 'SNAPSHOT'))
      provider.create
    end
    it 'should map exposed symbol to boolean' do
      Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:exposed => true))
      provider.create
    end
    it 'should map write_policy to writePolicy' do
      Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:writePolicy => 'ALLOW_WRITE_ONCE'))
      provider.create
    end
    it 'should map browseable symbol to boolean' do
      Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:browseable => true))
      provider.create
    end
    it 'should map indexable symbol to boolean' do
      Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:indexable => true))
      provider.create
    end
    it 'should map not_found_cache_ttl to notFoundCacheTTL' do
      Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:notFoundCacheTTL => 1440))
      provider.create
    end
    it 'should map local_storage_url to overrideLocalStorageUrl' do
      Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:overrideLocalStorageUrl => 'file:///some/path'))
      provider.create
    end
    it 'should map download_remote_indexes to downloadRemoteIndexes' do
      Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:downloadRemoteIndexes => false))
      provider.create
    end

    describe do
      let :provider do
        resource = Puppet::Type::Nexus_repository.new({
          :name          => 'example',
          :provider_type => 'maven1',
        })
        provider_class.new(resource)
      end

      it 'should auto-detect provider for provider_type => maven1' do
        Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:provider => 'maven1'))
        provider.create
      end
      it 'should auto-detect providerRole for provider_type => maven1' do
        Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:providerRole => 'org.sonatype.nexus.proxy.repository.Repository'))
        provider.create
      end
      it 'should auto-detect format for provider_type => maven1' do
        Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:format  => 'maven1'))
        provider.create
      end
    end

    describe do
      let(:provider) do
        resource = Puppet::Type::Nexus_repository.new({
          :name          => 'example',
          :provider_type => 'maven2',
        })
        provider_class.new(resource)
      end

      it 'should auto-detect provider for provider_type => maven2' do
        Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:provider => 'maven2'))
        provider.create
      end
      it 'should auto-detect providerRole for provider_type => maven2' do
        Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:providerRole => 'org.sonatype.nexus.proxy.repository.Repository'))
        provider.create
      end
      it 'should auto-detect format for provider_type => maven2' do
        Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:format => 'maven2'))
        provider.create
      end
    end

    describe do
      let(:provider) do
        resource = Puppet::Type::Nexus_repository.new({
          :name          => 'example',
          :provider_type => 'nuget',
        })
        provider_class.new(resource)
      end

      it 'should auto-detect provider for provider_type => nuget' do
        Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:provider => 'nuget-proxy'))
        provider.create
      end
      it 'should auto-detect providerRole for provider_type => nuget' do
        Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:providerRole => 'org.sonatype.nexus.proxy.repository.Repository'))
        provider.create
      end
      it 'should auto-detect format for provider_type => nuget' do
        Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:format => 'nuget'))
        provider.create
      end
    end

    describe do
      let(:provider) do
        resource = Puppet::Type::Nexus_repository.new({
          :name          => 'example',
          :provider_type => 'obr',
        })
        provider_class.new(resource)
      end

      it 'should auto-detect provider for provider_type => obr' do
        Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:provider => 'obr-proxy'))
        provider.create
      end
      it 'should auto-detect providerRole for provider_type => obr' do
        Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:providerRole => 'org.sonatype.nexus.proxy.repository.Repository'))
        provider.create
      end
      it 'should auto-detect format for provider_type => obr' do
        Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:format => 'obr'))
        provider.create
      end
    end

    describe do
      let(:provider) do
        resource = Puppet::Type::Nexus_repository.new({
          :name          => 'example',
          :provider_type => 'site',
        })
        provider_class.new(resource)
      end

      it 'should auto-detect provider for provider_type => site' do
        Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:provider => 'site'))
        provider.create
      end
      it 'should auto-detect providerRole for provider_type => site' do
        Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:providerRole => 'org.sonatype.nexus.proxy.repository.WebSiteRepository'))
        provider.create
      end
      it 'should auto-detect format for provider_type => site' do
        Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:format => 'site'))
        provider.create
      end
    end
end

  describe 'flush' do
    before(:each) do
      # mark resources as 'dirty'
      provider.policy = 'RELEASE'
    end
    it 'should use /service/local/repositories/example to update an existing resource' do
      Nexus::Rest.should_receive(:update).with('/service/local/repositories/example', anything())
      provider.flush
    end
    it 'should raise a human readable error message if the operation failed' do
      Nexus::Rest.should_receive(:update).and_raise('Operation failed')
      expect { provider.flush }.to raise_error(Puppet::Error, /Error while updating nexus_repository example/)
    end
    it 'should map name to id' do
      Nexus::Rest.should_receive(:update).with(anything, :data => hash_including(:id => 'example'))
      provider.flush
    end
    it 'should map type to repoType' do
      Nexus::Rest.should_receive(:update).with(anything, :data => hash_including(:repoType => 'hosted'))
      provider.flush
    end
    it 'should map provider_type to provider' do
      Nexus::Rest.should_receive(:update).with(anything, :data => hash_including(:provider => 'maven2'))
      provider.flush
    end
    it 'should map policy to repoPolicy' do
      Nexus::Rest.should_receive(:update).with(anything, :data => hash_including(:repoPolicy => 'SNAPSHOT'))
      provider.flush
    end
    it 'should map exposed symbol to boolean' do
      Nexus::Rest.should_receive(:update).with(anything, :data => hash_including(:exposed => true))
      provider.exposed = :true
      provider.flush
    end
    it 'should map write_policy to writePolicy' do
      Nexus::Rest.should_receive(:update).with(anything, :data => hash_including(:writePolicy => 'ALLOW_WRITE_ONCE'))
      provider.write_policy = :ALLOW_WRITE_ONCE
      provider.flush
    end
    it 'should map browseable symbol to boolean' do
      Nexus::Rest.should_receive(:update).with(anything, :data => hash_including(:browseable => true))
      provider.browseable = :true
      provider.flush
    end
    it 'should map indexable symbol to boolean' do
      Nexus::Rest.should_receive(:update).with(anything, :data => hash_including(:indexable => true))
      provider.indexable = :true
      provider.flush
    end
    it 'should map not_found_cache_ttl to notFoundCacheTTL' do
      Nexus::Rest.should_receive(:update).with(anything, :data => hash_including(:notFoundCacheTTL => 1440))
      provider.not_found_cache_ttl = 0
      provider.flush
    end
    it 'should map local_storage_url to overrideLocalStorageUrl' do
      Nexus::Rest.should_receive(:update).with(anything, :data => hash_including(:overrideLocalStorageUrl => 'file:///some/path'))
      provider.local_storage_url = 'file://some/path'
      provider.flush
    end
    it 'should map download_remote_indexes to downloadRemoteIndexes' do
      Nexus::Rest.should_receive(:update).with(anything, :data => hash_including(:downloadRemoteIndexes => false))
      provider.download_remote_indexes = :false
      provider.flush
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
  it 'should raise an error when the type is changed' do
    expect { provider.type = 'virtual' }.to raise_error(Puppet::Error, /type is write-once only/)
  end
  it 'should raise an error when the provider_type is changed' do
    expect { provider.provider_type = 'different' }.to raise_error(Puppet::Error, /provider_type is write-once only/)
  end
end
