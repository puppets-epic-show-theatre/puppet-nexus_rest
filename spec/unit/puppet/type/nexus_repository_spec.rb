require 'spec_helper'

describe Puppet::Type.type(:nexus_repository) do
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
      :label               => 'Maven1 Hosted Repository',
      :type                => :hosted,
      :provider_type       => :maven1,
      :policy              => :SNAPSHOT,
      :write_policy        => :READ_ONLY,
      :browseable          => true,
      :indexable           => true,
      :not_found_cache_ttl => 0
    )
  end
  it 'should accept hosted Maven2 repository' do
    Puppet::Type.type(:nexus_repository).new(
      :name                => 'maven2-hosted',
      :label               => 'Maven2 Hosted Repository',
      :type                => :hosted,
      :provider_type       => :maven2,
      :policy              => :RELEASE,
      :write_policy        => :ALLOW_WRITE_ONCE,
      :browseable          => true,
      :indexable           => true,
      :not_found_cache_ttl => 0
    )
  end
  it 'should not accept local_storage_url => \'\'' do
    expect {
      Puppet::Type.type(:nexus_repository).new(
        :name                => 'maven2-hosted',
        :label               => 'Maven2 Hosted Repository',
        :type                => :hosted,
        :provider_type       => :maven2,
        :policy              => :RELEASE,
        :write_policy        => :ALLOW_WRITE_ONCE,
        :browseable          => true,
        :indexable           => true,
        :not_found_cache_ttl => 0,
        :local_storage_url   => ''
      )
    }.to raise_error(Puppet::Error, /Invalid local_storage_url/)
  end
end
