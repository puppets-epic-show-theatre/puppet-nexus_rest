require 'spec_helper'

describe Puppet::Type.type(:nexus_repository_route) do
  describe 'by default' do
    let(:repository) { Puppet::Type.type(:nexus_repository_route).new(:title => 'default', :position => '0') }

    it { expect(repository[:rule_type]).to eq(:inclusive) }
  end

  it 'should reject non-integer name' do
    expect {
      Puppet::Type.type(:nexus_repository_route).new(
        :name          => 'not a number'
      )
    }.to raise_error(Puppet::ResourceError, /position must be a non-negative integer, got 'not a number'/)
  end

  it 'should reject non-integer position' do
    expect {
      Puppet::Type.type(:nexus_repository_route).new(
        :position          => 'not a number'
      )
    }.to raise_error(Puppet::ResourceError, /position must be a non-negative integer, got 'not a number'/)
  end

  it 'should accept an integer name' do
    Puppet::Type.type(:nexus_repository_route).new(
      :position          => '0'
    )
  end

  it 'it should accept a url_pattern' do
    Puppet::Type.type(:nexus_repository_route).new(
      #required values
      :position            => '0',
      :repository_group    => 'repo-group',
      :repositories        => 'repo',

      :url_pattern       => 'some_pattern'
    )
  end

  it 'it should reject empty url_pattern' do
    expect {
      Puppet::Type.type(:nexus_repository_route).new(
        #required values
        :position          => '0',
        :repository_group  => 'repo-group',
        :repositories      => 'repo',

        :url_pattern       => ''
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
      :rule_type           => :exclusive
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

        :repository_group    => ''
      )
    }.to raise_error(Puppet::Error, /route repository_group must not be empty/)
  end

  it 'should reject empty repositories list when inclusive' do
    expect {
      Puppet::Type.type(:nexus_repository_route).new(
        #required values
        :position            => '0',
        :rule_type           => :inclusive,
        :repository_group    => 'repo-group',
        :repositories        => 'repo',
        :url_pattern         => 'some_pattern',

        :repositories        => []
      )
    }.to raise_error(Puppet::Error, /route repositories must not be empty if rule_type is not 'blocking'/)
  end

  it 'should reject undefined repositories list when inclusive' do
    expect {
      Puppet::Type.type(:nexus_repository_route).new(
        #required values
        :position            => '0',
        :rule_type           => :inclusive,
        :repository_group    => 'repo-group',
        :url_pattern         => 'some_pattern'
      )
    }.to raise_error(Puppet::Error, /route repositories must not be empty if rule_type is not 'blocking'/)
  end

  it 'should accept empty repositories list when blocking' do
    Puppet::Type.type(:nexus_repository_route).new(
      #required values
      :position            => '0',
      :rule_type           => :blocking,
      :repository_group    => 'repo-group',
      :repositories        => 'repo',
      :url_pattern         => 'some_pattern',

      :repositories        => []
    )
  end

  it 'should accept undefined repositories list when blocking' do
    Puppet::Type.type(:nexus_repository_route).new(
      #required values
      :position            => '0',
      :rule_type           => :blocking,
      :repository_group    => 'repo-group',
      :url_pattern         => 'some_pattern'
    )
  end

  it 'should reject non-empty repositories list when blocking' do
    expect {
      Puppet::Type.type(:nexus_repository_route).new(
        #required values
        :position            => '0',
        :rule_type           => :blocking,
        :repository_group    => 'repo-group',
        :repositories        => 'repo',
        :url_pattern         => 'some_pattern',

        :repositories        => ['repo1', 'repo2']
      )
    }.to raise_error(Puppet::Error, /route repositories must be empty if rule_type is 'blocking'/)
  end

end
