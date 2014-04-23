require 'spec_helper'

describe Puppet::Type.type(:nexus_repository) do
  describe 'by default' do
    let(:repository) { Puppet::Type.type(:nexus_repository).new(:name => 'default') }

    it { expect(repository[:type]).to eq(:hosted) }
    it { expect(repository[:provider_type]).to eq(:maven2) }
    it { expect(repository[:policy]).to eq(:RELEASE) }
    it { expect(repository[:exposed]).to eq(:true) }
    it { expect(repository[:write_policy]).to eq(:ALLOW_WRITE_ONCE) }
    it { expect(repository[:browseable]).to eq(:true) }
    it { expect(repository[:indexable]).to eq(:true) }
    it { expect(repository[:not_found_cache_ttl]).to eq(1440) }
    it { expect(repository[:local_storage_url]).to eq(nil) }
    it { expect(repository[:download_remote_indexes]).to eq(:false) }
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
end
