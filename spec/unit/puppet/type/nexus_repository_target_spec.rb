require 'spec_helper'

describe Puppet::Type.type(:nexus_repository_target) do
  describe 'by default' do
    let(:repository) { Puppet::Type.type(:nexus_repository_target).new(:name => 'default-target') }

    it { expect(repository[:provider_type]).to eq(:maven2) }
    it { expect(repository[:patterns]).to eq([]) }
  end

  it 'should not accept empty provider_type' do
    expect {
      Puppet::Type.type(:nexus_repository_target).new(
        :name          => 'example-target',
        :provider_type => ''
      )
    }.to raise_error(Puppet::Error, /must be a non-empty string/)
  end

  it 'should accept Maven1 repository target' do
    Puppet::Type.type(:nexus_repository_target).new(
      :name                => 'maven1-target',
      :label               => 'Maven1 Target',
      :provider_type       => :maven1,
      :patterns            => ['^/com/acme/.*']
    )
  end

  it 'should accept Maven2 repository target' do
    Puppet::Type.type(:nexus_repository_target).new(
      :name                => 'maven2-target',
      :label               => 'Maven2 Target',
      :provider_type       => :maven2,
      :patterns            => ['^/com/acme/.*']
    )
  end

end
