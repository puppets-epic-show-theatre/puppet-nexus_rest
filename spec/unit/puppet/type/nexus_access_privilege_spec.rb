require 'spec_helper'

describe Puppet::Type.type(:nexus_access_privilege) do
  describe 'by default' do
    let(:privilege) { Puppet::Type.type(:nexus_access_privilege).new(
      :name => 'name',
      :description => 'description',
      :methods => 'read,create',
      :repository_target => 'repository_target',
      :repository => 'repository',
    ) }

    it { expect(privilege[:repository_group]).to eq('') }
  end

  it 'should accept valid targets' do
    Puppet::Type.type(:nexus_access_privilege).new(
      :name              => 'name',
      :description       => 'description',
      :repository_target => 'repository_target',
      :repository        => 'repository',
      :methods           => ['read', 'update', 'create', 'delete'],
    )
  end

  it 'should reject invalid targets' do
    expect {
      Puppet::Type.type(:nexus_access_privilege).new(
        :name              => 'name',
        :description       => 'description',
        :repository_target => 'repository_target',
        :repository        => 'repository',
        :methods           => ['invalid', 'read'],
      )
    }.to raise_error(Puppet::Error, /methods must one or more of these values/)
  end

  it 'should require that either repository or repository_group is defined' do
    expect {
      Puppet::Type.type(:nexus_access_privilege).new(
        :name              => 'name',
        :description       => 'description',
        :repository_target => 'repository_target',
        :methods           => 'read',
      )
    }.to raise_error(Puppet::Error, /either repository or repository_group must be specified/)
  end

  it 'should not allow both repository and repository_group to be defined' do
    expect {
      Puppet::Type.type(:nexus_access_privilege).new(
        :name              => 'name',
        :description       => 'description',
        :repository_target => 'repository_target',
        :methods           => 'read',
        :repository        => 'repository',
        :repository_group  => 'repository_group',
      )
    }.to raise_error(Puppet::Error, /repository and repository_group must not both be specified/)
  end

  #it 'should accept Maven1 repository target' do
  #  Puppet::Type.type(:nexus_access_privilege).new(
  #    :name                => 'maven1-target',
  #    :label               => 'Maven1 Target',
  #    :provider_type       => :maven1,
  #    :patterns            => ['^/com/acme/.*']
  #  )
  #end

  #it 'should accept Maven2 repository target' do
  #  Puppet::Type.type(:nexus_access_privilege).new(
  #    :name                => 'maven2-target',
  #    :label               => 'Maven2 Target',
  #    :provider_type       => :maven2,
  #    :patterns            => ['^/com/acme/.*']
  #  )
  #end

end
