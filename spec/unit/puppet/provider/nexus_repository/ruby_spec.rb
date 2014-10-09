require 'spec_helper'

provider_class = Puppet::Type.type(:nexus_repository).provider(:ruby)

describe provider_class do
  before(:each) do
    Nexus::Config.stub(:resolve).and_return('http://example.com/foobar')
    Nexus::Config.stub(:can_delete_repositories).and_return(true)
  end

  let :provider do
    resource = Puppet::Type::Nexus_repository.new({
      :name                    => 'example',
      :label                   => 'Example Repository',
      :provider_type           => 'maven2',
      :type                    => 'hosted',
      :policy                  => :snapshot,
      :exposed                 => :true,
      :write_policy            => :allow_write_once,
      :browseable              => :true,
      :indexable               => :true,
      :not_found_cache_ttl     => 1440,
      :local_storage_url       => 'file:///some/path',
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
    it { expect(instance.provider_type).to eq(:maven2) }
    it { expect(instance.type).to eq(:hosted) }
    it { expect(instance.policy).to eq(:snapshot) }
    it { expect(instance.exposed).to eq(:true) }
    it { expect(instance.write_policy).to eq(:allow_write_once) }
    it { expect(instance.browseable).to eq(:true) }
    it { expect(instance.indexable).to eq(:true) }
    it { expect(instance.not_found_cache_ttl).to eq(0) }
    it { expect(instance.local_storage_url).to eq('file:///some/path') }
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
    it { expect(instance.provider_type).to eq(:nuget) }
    it { expect(instance.type).to eq(:hosted) }
    it { expect(instance.exposed).to eq(:false) }
    it { expect(instance.write_policy).to eq(:read_only) }
    it { expect(instance.browseable).to eq(:false) }
    it { expect(instance.indexable).to eq(:false) }
    it { expect(instance.not_found_cache_ttl).to eq(0) }
    it { expect(instance.local_storage_url).to eq(:absent) }
    it { expect(instance.exists?).to be_true }
  end

  $proxy_template = {
    'data' => [{
      'id'                            => 'repository-3',
      'name'                          => 'a repository proxy',
      'repoType'                      => 'proxy',
      'repoPolicy'                    => 'RELEASE',
      'writePolicy'                   => 'READ_ONLY',
      'browseable'                    => true,
      'exposed'                       => true,
      'notFoundCacheTTL'              => 1440,
      'autoBlockActive'               => true,
      'checksumPolicy'                => 'STRICT',
      'downloadRemoteIndexes'         => true,
      'fileTypeValidation'            => false,
      'itemMaxAge'                    => 1445,
      'artifactMaxAge'                => -1,
      'metadataMaxAge'                => 1450,
      'remoteStorage'                 => {
        'remoteStorageUrl'            =>  'http://maven-repo/',
        'connectionSettings'          => {
          'connectionTimeout'         => 9001,
          'retrievalRetryCount'       => 3,
          'queryString'               => 'param1=a&amp;param2=b',
          'userAgentString'           => 'user-agent'
        },
        'authentication'              => {
          'username'                  => 'username',
          'password'                  => 'secret',
          'ntlmHost'                  => 'nt-lan-host',
          'ntlmDomain'                => 'nt-manager-domain'
        }
      }
    }]
  }

  $proxy_template_without_auth = Marshal.load(Marshal.dump($proxy_template)) 
  $proxy_template_without_auth['data'][0]['remoteStorage']['authentication'].delete('username')
  $proxy_template_without_auth['data'][0]['remoteStorage']['authentication'].delete('password')


  describe 'a proxy instance' do
    let :instance do
      Nexus::Rest.should_receive(:get_all_plus_n).with('/service/local/repositories').and_return($proxy_template)
      provider_class.instances[0]
    end

    it { expect(instance.name).to eq('repository-3') }
    it { expect(instance.label).to eq('a repository proxy') }
    it { expect(instance.type).to eq(:proxy) }
    it { expect(instance.policy).to eq(:release) }
    it { expect(instance.write_policy).to eq(:read_only) }
    it { expect(instance.not_found_cache_ttl).to eq(1440) }
    it { expect(instance.remote_storage).to eq('http://maven-repo/') }
    it { expect(instance.remote_auto_block).to eq(:true) }
    it { expect(instance.remote_checksum_policy).to eq(:strict) }
    it { expect(instance.remote_download_indexes).to eq(:true) }
    it { expect(instance.remote_file_validation).to eq(:false) }
    it { expect(instance.remote_item_max_age).to eq(1445) }
    it { expect(instance.remote_artifact_max_age).to eq(-1) }
    it { expect(instance.remote_metadata_max_age).to eq(1450) }
    it { expect(instance.remote_request_timeout).to eq(9001) }
    it { expect(instance.remote_request_retries).to eq(3) }
    it { expect(instance.remote_query_string).to eq('param1=a&param2=b') }
    it { expect(instance.remote_user_agent).to eq('user-agent') }
    it { expect(instance.remote_user).to eq('username') }
    it { expect(instance.remote_password_ensure).to eq(:present) }
    it { expect(instance.remote_ntlm_host).to eq('nt-lan-host') }
    it { expect(instance.remote_ntlm_domain).to eq('nt-manager-domain') }
    it { expect(instance.exists?).to be_true }
  end

  describe 'a proxy instance without authentication' do
    let :instance do
      Nexus::Rest.should_receive(:get_all_plus_n).with('/service/local/repositories').and_return($proxy_template_without_auth)
      provider_class.instances[0]
    end
    it { expect(instance.remote_password_ensure).to eq(:absent) }
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
          :name                   => 'example-proxy',
          :type                   => :proxy,
          :remote_storage         => 'http://some-maven-repo/',
          :remote_user            => 'proxy-user',
          :remote_password        => 'proxy-password',
          :remote_password_ensure => :present,
        })
        provider_class.new(resource)
      end

      it 'should map remote_storage to remoteStorage.remoteStorageUrl' do
        Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:remoteStorage => hash_including(:remoteStorageUrl => 'http://some-maven-repo/')))
        provider.create
      end
      it 'should select default value and map remote_auto_block to autoBlockActive' do
        Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:autoBlockActive => true))
        provider.create
      end
      it 'should select default value and map label to remote_checksum_policy' do
        Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:checksumPolicy => 'WARN'))
        provider.create
      end
      it 'should select default value and map remote_download_indexes to downloadRemoteIndexes' do
        Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:downloadRemoteIndexes => true))
        provider.create
      end
      it 'should select default value and map remote_file_validation to fileTypeValidation' do
        Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:fileTypeValidation => true))
        provider.create
      end
      it 'should select default value and map remote_item_max_age to itemMaxAge' do
        Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:itemMaxAge => 1440))
        provider.create
      end
      it 'should select default value and map remote_artifact_max_age to artifactMaxAge' do
        Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:artifactMaxAge => -1))
        provider.create
      end
      it 'should select default value and map remote_metadata_max_age to metadataMaxAge' do
        Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:metadataMaxAge => 1440))
        provider.create
      end
      it 'should map remote_user to remoteStorage.authentication.username' do
        Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:remoteStorage => hash_including(:authentication => hash_including(:username => 'proxy-user'))))
        provider.create
      end
      it 'should map remote_password to remoteStorage.authentication.password' do
        Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:remoteStorage => hash_including(:authentication => hash_including(:password => 'proxy-password'))))
        provider.create
      end
      it 'should map remote_request_timeout to remoteStorage.connectionSettings.connectionTimeout' do
        Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:remoteStorage => hash_including(:connectionSettings => hash_including(:connectionTimeout => 60))))
        provider.create
      end
      it 'should map remote_request_retries to remoteStorage.connectionSettings.retrievalRetryCount' do
        Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:remoteStorage => hash_including(:connectionSettings => hash_including(:retrievalRetryCount => 10))))
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
      it 'should select `mixed` policy for provider_type => nuget' do
        Nexus::Rest.should_receive(:create).with(anything, :data => hash_including(:repoPolicy => 'MIXED'))
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
      provider.policy = :release
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
    specify 'should fail if configuration prevents deletion of repositories' do
      Nexus::Config.stub(:can_delete_repositories).and_return(false)
      expect { provider.destroy }.to raise_error(RuntimeError, /current configuration prevents the deletion of nexus_repository example/)
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
