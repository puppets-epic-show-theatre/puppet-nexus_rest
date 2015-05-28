require 'spec_helper'

describe Puppet::Type.type(:nexus_repository_group) do
  describe 'by default' do
    let(:group) { Puppet::Type.type(:nexus_repository_group).new(:name => 'default') }

    it { expect(group[:provider_type]).to eq(:maven2) }
    it { expect(group[:exposed]).to eq(:true) }
  end

  it 'should validate provider_type' do
    expect {
      Puppet::Type.type(:nexus_repository_group).new(
        :name          => 'example',
        :provider_type => 'invalid'
      )
    }.to raise_error(Puppet::Error, /Invalid value "invalid"/)
  end

  it 'should accept Maven1 group repository' do
    Puppet::Type.type(:nexus_repository_group).new(
      :name                => 'mvn1-group',
      :label               => 'maven 1 group',
      :provider_type       => :maven1
    )
  end

  it 'should accept Maven2 group repository' do
    Puppet::Type.type(:nexus_repository_group).new(
      :name                => 'mvn2-group',
      :label               => 'maven 2 group',
      :provider_type       => :maven2
    )
  end

  it 'should accept some repositories' do
    Puppet::Type.type(:nexus_repository_group).new(
      :name                => 'group-repository',
      :label               => 'group repository',
      :repositories        => ['repo-c', 'repo-d']
    )

  end
end

