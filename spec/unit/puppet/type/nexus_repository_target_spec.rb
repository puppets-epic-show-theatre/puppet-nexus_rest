require 'spec_helper'

describe Puppet::Type.type(:nexus_repository_target) do
  describe 'by default' do
    let(:repository) { Puppet::Type.type(:nexus_repository_target).new(:name => 'default-target') }

    it { expect(repository[:provider_type]).to eq(:maven2) }
    it { expect(repository[:patterns]).to eq([]) }
  end

  it 'should validate provider_type' do
    expect {
      Puppet::Type.type(:nexus_repository_target).new(
        :name          => 'example-target',
        :provider_type => 'invalid'
      )
    }.to raise_error(Puppet::Error, /Invalid value "invalid"/)
  end

  it 'should accept hosted Maven1 repository' do
    Puppet::Type.type(:nexus_repository_target).new(
      :name                => 'maven1-target',
      :provider_type       => :maven1
    )
  end

  it 'should accept hosted Maven2 repository' do
    Puppet::Type.type(:nexus_repository_target).new(
      :name                => 'maven2-target',
      :provider_type       => :maven2
    )
  end

end
