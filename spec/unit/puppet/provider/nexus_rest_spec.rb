require 'spec_helper'
include WebMock::API

describe Nexus::Rest do
  describe 'instances' do
    let :instances do
      stub_request(:any, 'example.com/service/local/repositories').to_return(:body => '{ "data": [{"id": "repository-1"}, {"id": "repository-2"}] }')
      Nexus::Rest.get_all('/service/local/repositories')
    end

    it { instances['data'].should have(2).items }
  end

  describe 'create' do
    it 'should submit a POST to /service/local/repositories' do
      stub = stub_request(:post, 'example.com/service/local/repositories').to_return(:status => 200)
      Nexus::Rest.create('/service/local/repositories')
      stub.should have_been_requested
    end

    it 'should raise an error if response is not expected' do
      stub_request(:any, 'example.com/service/local/repositories').to_return(:status => 503)
      expect {
        Nexus::Rest.create('/service/local/repositories')
      }.to raise_error
    end
  end

  describe 'update' do
    it 'should submit a PUT to /service/local/repositories/example' do
      stub = stub_request(:put, 'example.com/service/local/repositories/example').to_return(:status => 200)
      Nexus::Rest.update('/service/local/repositories/example')
      stub.should have_been_requested
    end

    it 'should raise an error if response is not expected' do
      stub_request(:any, 'example.com/service/local/repositories/example').to_return(:status => 503)
      expect {
        Nexus::Rest.update('/service/local/repositories/example')
      }.to raise_error
    end
  end

  describe 'destroy' do
    it 'should submit a DELETE to /service/local/repositories/example' do
      stub = stub_request(:delete, 'example.com/service/local/repositories/example').to_return(:status => 200)
      Nexus::Rest.destroy('/service/local/repositories/example')
      stub.should have_been_requested
    end

    it 'should not fail if resource already deleted' do
      stub = stub_request(:delete, 'example.com/service/local/repositories/example').to_return(:status => 404)
      Nexus::Rest.destroy('/service/local/repositories/example')
      stub.should have_been_requested
    end

    it 'should raise an error if response is not expected' do
      stub_request(:delete, 'example.com/service/local/repositories/example').to_return(:status => 503)
      expect {
        Nexus::Rest.destroy('/service/local/repositories/example')
      }.to raise_error
    end
  end
end
