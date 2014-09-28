require 'spec_helper'

describe Puppet::Type.type(:nexus_repository) do
  let(:defaults) { {:name => 'any'} }

  describe 'by default' do
    let(:repository) { Puppet::Type.type(:nexus_repository).new(:name => 'default') }

    it { expect(repository[:type]).to eq(:hosted) }
    it { expect(repository[:provider_type]).to eq(:maven2) }
    it { expect(repository[:policy]).to eq(:release) }
    it { expect(repository[:exposed]).to eq(:true) }
    it { expect(repository[:write_policy]).to eq(:allow_write_once) }
    it { expect(repository[:browseable]).to eq(:true) }
    it { expect(repository[:indexable]).to eq(:true) }
    it { expect(repository[:not_found_cache_ttl]).to eq(1440) }
    it { expect(repository[:local_storage_url]).to eq(nil) }
  end

  describe 'by default non-maven' do
    let(:repository) { Puppet::Type.type(:nexus_repository).new(:name => 'default-nuget', :provider_type => :nuget) }

    it { expect(repository[:policy]).to eq(:mixed) }
  end

  describe 'by default with proxy' do
    let(:repository) { Puppet::Type.type(:nexus_repository).new(
      :name => 'default-proxy',
      :type => 'proxy',
      :remote_storage => 'http://maven-repo/'
    ) }

    it { expect(repository[:remote_storage]).to eq('http://maven-repo/') }
    it { expect(repository[:remote_download_indexes]).to eq(:true) }
    it { expect(repository[:remote_auto_block]).to eq(:true) }
    it { expect(repository[:remote_file_validation]).to eq(:true) }
    it { expect(repository[:remote_checksum_policy]).to eq(:warn) }
    it { expect(repository[:remote_artifact_max_age]).to eq(-1) }
    it { expect(repository[:remote_metadata_max_age]).to eq(1440) }
    it { expect(repository[:remote_item_max_age]).to eq(1440) }
  end

  it 'should validate provider_type' do
    expect {
      Puppet::Type.type(:nexus_repository).new(
        :name          => 'example',
        :provider_type => 'invalid'
      )
    }.to raise_error(Puppet::Error, /Invalid value "invalid"/)
  end

  it 'should accept hosted Maven1 repository' do
    Puppet::Type.type(:nexus_repository).new(
      :name                => 'maven1-hosted',
      :type                => :hosted,
      :provider_type       => :maven1
    )
  end

  it 'should accept hosted Maven2 repository' do
    Puppet::Type.type(:nexus_repository).new(
      :name                => 'maven2-hosted',
      :type                => :hosted,
      :provider_type       => :maven2
    )
  end

  it 'should not accept local_storage_url => \'\'' do
    expect {
      Puppet::Type.type(:nexus_repository).new(
        :name                => 'maven2-hosted',
        :local_storage_url   => ''
      )
    }.to raise_error(Puppet::Error, /Invalid local_storage_url/)
  end

  specify 'should accept absolute local_storage_url' do
    expect { described_class.new(defaults.merge(:local_storage_url => '/absolute/path')) }.to_not raise_error
  end

  specify 'should not accept absolute local_storage_url' do
    expect { described_class.new(defaults.merge(:local_storage_url => 'relative/path')) }.to raise_error(Puppet::Error, /Invalid local_storage_url/)
  end

  it 'should not accept any other policy except mixed for non-maven provider_types' do
    expect {
      Puppet::Type.type(:nexus_repository).new(
        :name                => 'nuget-repo',
        :type                => :hosted,
        :provider_type       => :nuget,
        :policy              => :release
      )
    }.to raise_error(Puppet::ResourceError, /'policy' must be 'mixed'/)
  end

  it 'should accept proxy repository' do
    Puppet::Type.type(:nexus_repository).new(
      :name                => 'proxy-repo',
      :type                => :proxy,
      :remote_storage      => 'http://maven-proxy/'
    )
  end

  it 'should not accept proxy if no remote_storage is defined' do
    expect {
      Puppet::Type.type(:nexus_repository).new(
        :name                => 'proxy-repo',
        :type                => :proxy
      )
    }.to raise_error(Puppet::ResourceError, /'remote_storage' must be set/)
  end

  it 'should not accept proxy-only values if not proxy type' do
    expect {
      Puppet::Type.type(:nexus_repository).new(
        :name                => 'non-proxy-repo',
        :remote_storage      => 'http://maven-proxy/'
      )
    }.to raise_error(Puppet::ResourceError, /'remote_storage' must not be set/)
  end

end
