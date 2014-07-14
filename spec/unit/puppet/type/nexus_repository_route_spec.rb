require 'spec_helper'

describe Puppet::Type.type(:nexus_repository_route) do
  describe 'by default' do
    let(:repository) { Puppet::Type.type(:nexus_repository_route).new(:title => 'default', :position => '0') }

    it { expect(repository[:rule_type]).to eq(:inclusive) }
  end

  it 'should reject non-integer name' do
    expect {
      Puppet::Type.type(:nexus_repository_route).new(
        :name          => 'not a number',
      )
    }.to raise_error(Puppet::ResourceError, /invalid value for Integer/)
  end

  it 'should reject non-integer position' do
    expect {
      Puppet::Type.type(:nexus_repository_route).new(
        :position          => 'not a number',
      )
    }.to raise_error(Puppet::ResourceError, /invalid value for Integer/)
  end

  it 'should accept an integer name' do
    Puppet::Type.type(:nexus_repository_route).new(
      :position          => '0',
    )
  end

  it 'it should accept a url_pattern' do
    Puppet::Type.type(:nexus_repository_route).new(
      #required values
      :position            => '0',
      :repository_group    => 'repo-group',
      :repositories        => 'repo',

      :url_pattern       => 'some_pattern',
    )
  end

  it 'it should reject empty url_pattern' do
    expect {
      Puppet::Type.type(:nexus_repository_route).new(
        #required values
        :position          => '0',
        :repository_group  => 'repo-group',
        :repositories      => 'repo',

        :url_pattern       => '',
      )
    }.to raise_error(Puppet::Error, /route url_pattern must not be empty/)
  end

  it 'should accept exclusive rule_type' do
    Puppet::Type.type(:nexus_repository_route).new(
      #required values
      :position            => '0',
      :repository_group    => 'repo-group',
      :repositories        => 'repo',
      :url_pattern         => 'some_pattern',

      #test
      :rule_type           => :exclusive,
    )
  end

  it 'should reject empty repository_group' do
    expect {
      Puppet::Type.type(:nexus_repository_route).new(
        #required values
        :position            => '0',
        :repository_group    => 'repo-group',
        :repositories        => 'repo',
        :url_pattern         => 'some_pattern',

        :repository_group    => '',
      )
    }.to raise_error(Puppet::Error, /route repository_group must not be empty/)
  end

  it 'should reject empty repositories list' do
    expect {
      Puppet::Type.type(:nexus_repository_route).new(
        #required values
        :position            => '0',
        :repository_group    => 'repo-group',
        :repositories        => 'repo',
        :url_pattern         => 'some_pattern',

        :repositories        => [],
      )
    }.to raise_error(Puppet::Error, /route repositories list must not be empty/)
  end
end
