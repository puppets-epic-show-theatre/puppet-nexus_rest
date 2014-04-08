require 'spec_helper'
include WebMock::API

provider_class = Puppet::Type.type(:nexus_repository).provider(:ruby)

describe provider_class do

  describe "exists" do
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
      stub_request(:any, 'example.com/service/local/repositories/example').to_return(:status => 404)

      provider.exists?.should be_false
    end

    it "should return true if response is ok" do
      stub_request(:any, 'example.com/service/local/repositories/example').to_return(:status => 200)

      provider.exists?.should be_true
    end

    it "should raise an error if response is not expected" do
      stub_request(:any, 'example.com/service/local/repositories/example').to_return(:status => 503)

      expect { provider.exists? }.to raise_error
    end
  end

  describe 'create' do
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

    it 'should submit a POST to /service/local/repositories' do
      stub = stub_request(:post, 'example.com/service/local/repositories').to_return(:status => 200)
      provider.create
      stub.should have_been_requested
    end

    it 'should raise an error if response is not expected' do
      stub = stub_request(:any, 'example.com/service/local/repositories').to_return(:status => 503)
      provider.create
      stub.should have_been_requested
    end
  end

  describe 'destroy' do
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

    it 'should submit a DELETE to /service/local/repositories/example' do
      stub = stub_request(:delete, 'example.com/service/local/repositories/example').to_return(:status => 200)
      provider.destroy
      stub.should have_been_requested
    end

    it 'should not fail if resource already deleted' do
      stub = stub_request(:delete, 'example.com/service/local/repositories/example').to_return(:status => 404)
      provider.destroy
      stub.should have_been_requested
    end

    it 'should raise an error if response is not expected' do
      stub_request(:delete, 'example.com/service/local/repositories/example').to_return(:status => 503)
      expect { provider.destroy }.to raise_error
    end
  end
end
