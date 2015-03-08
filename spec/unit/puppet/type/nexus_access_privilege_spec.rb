require 'spec_helper'

describe Puppet::Type.type(:nexus_access_privilege) do
  describe 'by default' do
    let(:privilege) { Puppet::Type.type(:nexus_access_privilege).new(
      :name              => 'name',
      :description       => 'description',
      :methods           => ['read', 'create'],
      :repository_target => 'repository_target'
    ) }

    it { expect(privilege[:repository_group]).to eq('') }
    it { expect(privilege[:repository]).to eq('') }

  end

  it 'should accept valid targets' do
    Puppet::Type.type(:nexus_access_privilege).new(
      :name              => 'name',
      :description       => 'description',
      :repository_target => 'repository_target',
      :repository        => 'repository',
      :methods           => ['read', 'update', 'create', 'delete']
    )
  end

  it 'should reject invalid targets' do
    expect {
      Puppet::Type.type(:nexus_access_privilege).new(
        :name              => 'name',
        :description       => 'description',
        :repository_target => 'repository_target',
        :repository        => 'repository',
        :methods           => ['invalid', 'read']
      )
    }.to raise_error(Puppet::Error, /methods must one or more of these values/)
  end

  it 'should require that repository_target is defined' do
    expect {
      Puppet::Type.type(:nexus_access_privilege).new(
        :name              => 'name',
        :description       => 'description',
        :repository        => 'repository',
        :methods           => 'read'
      )
    }.to raise_error(Puppet::Error, /repository_target must be defined/)
  end

  it 'should not allow both repository and repository_group to be defined' do
    expect {
      Puppet::Type.type(:nexus_access_privilege).new(
        :name              => 'name',
        :description       => 'description',
        :repository_target => 'repository_target',
        :methods           => 'read',
        :repository        => 'repository',
        :repository_group  => 'repository_group'
      )
    }.to raise_error(Puppet::Error, /repository and repository_group must not both be non-empty/)
  end

  it 'should require a description' do
    expect {
      Puppet::Type.type(:nexus_access_privilege).new(
        :name              => 'name',
        :repository_target => 'repository_target',
        :methods           => 'read',
        :repository        => 'repository',
        :repository_group  => 'repository_group'
      )
    }.to raise_error(Puppet::Error, /description must be defined/)
  end

end
