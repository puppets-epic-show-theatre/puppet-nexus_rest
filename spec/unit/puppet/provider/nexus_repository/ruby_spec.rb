require 'spec_helper'
include WebMock::API

provider_class = Puppet::Type.type(:nexus_repository).provider(:ruby)

describe provider_class do

    let :provider do
      resource = Puppet::Type::Nexus_repository.new(
        {
            :name     => 'example',
            :baseurl  => 'http://example.com',
            :resource => "/api/users",
            :timeout  => 10
        }
      )
      provider_class.new(resource)
    end

    it "should return false if response is not found" do
      stub_request(:any, 'example.com/api/resource').to_return(:status => 404)

      provider.exists?.should be_false
    end

    it "should return true if response is ok" do
      stub_request(:any, 'example.com/api/resource').to_return(:status => 200)

      provider.exists?.should be_true
    end

    it "should return raise an error if response is not expected" do
      stub_request(:any, 'example.com/api/resource').to_return(:status => 503)

      expect { provider.exists? }.to raise_error
    end
end

