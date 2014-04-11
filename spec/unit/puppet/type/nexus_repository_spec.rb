require 'spec_helper'

describe Puppet::Type.type(:nexus_repository) do
  it 'should validate provider_type' do
    expect {
      Puppet::Type.type(:nexus_repository).new(
        :name          => 'example',
        :provider_type => 'invalid'
      )
    }.to raise_error(Puppet::Error, /value is not supported \'invalid\'/)
  end
end