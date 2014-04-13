require 'spec_helper'
include WebMock::API

describe Nexus::Rest do
  before(:each) do
    Nexus::Config.stub(:read_config).and_return({
      :base_url       => 'http://example.com',
      :admin_username => 'foobar',
      :admin_password => 'secret'
    })
  end

  after(:each) do
    Nexus::Rest.reset
  end

  describe 'get_all' do
    it 'should parse JSON response' do
      stub_request(:any, 'example.com/service/local/repositories').to_return(:body => '{ "data": [{"id": "repository-1"}, {"id": "repository-2"}] }')
      instances = Nexus::Rest.get_all('/service/local/repositories')
      instances['data'].should have(2).items
    end

    it 'should accept only application/json' do
      stub = stub_request(:get, /.*/).with(:headers => {'Accept' => 'application/json'}).to_return(:body => '{}')
      Nexus::Rest.get_all('/service/local/repositories')
      stub.should have_been_requested
    end
  end

  describe 'create' do
    it 'should submit a POST to /service/local/repositories' do
      stub = stub_request(:post, /example.com\/service\/local\/repositories/).to_return(:status => 200)
      Nexus::Rest.create('/service/local/repositories', {})
      stub.should have_been_requested
    end

    it 'should use content type application/json' do
      stub = stub_request(:post, /.*/).with(:headers => {'Content-Type' => 'application/json'}, :body => {}).to_return(:status => 200)
      Nexus::Rest.create('/service/local/repositories', {})
      stub.should have_been_requested
    end

    it 'should send admin credentials' do
      stub = stub_request(:post, /foobar:secret@example.com.*/).to_return(:status => 200)
      Nexus::Rest.create('/service/local/repositories', {'data' => {'id' => 'foobar'}})
      stub.should have_been_requested
    end

    it 'should submit the passed data' do
      stub = stub_request(:post, /.*/).with(:body => {:data => {:a => '1', :b => 'five'}}).to_return(:status => 200)
      Nexus::Rest.create('/service/local/repositories', {'data' => {:a => '1', :b => 'five'}})
      stub.should have_been_requested
    end

    it 'should raise an error if response is not expected' do
      stub_request(:any, /.*/).to_return(:status => 503)
      expect {
        Nexus::Rest.create('/service/local/repositories', {})
      }.to raise_error(RuntimeError, /Failed to submit POST/)
    end
  end

  describe 'update' do
    it 'should submit a PUT to /service/local/repositories/example' do
      stub = stub_request(:put, /example.com\/service\/local\/repositories/).to_return(:status => 200)
      Nexus::Rest.update('/service/local/repositories/example', {})
      stub.should have_been_requested
    end

    it 'should raise an error if response is not expected' do
      stub_request(:any, /.*/).to_return(:status => 503)
      expect {
        Nexus::Rest.update('/service/local/repositories/example', {})
      }.to raise_error(RuntimeError, /Failed to submit PUT/)
    end
  end

  describe 'destroy' do
    it 'should submit a DELETE to /service/local/repositories/example' do
      stub = stub_request(:delete, /example.com\/service\/local\/repositories\/example/).to_return(:status => 200)
      Nexus::Rest.destroy('/service/local/repositories/example')
      stub.should have_been_requested
    end

    it 'should not fail if resource already deleted' do
      stub = stub_request(:delete, /.*/).to_return(:status => 404)
      Nexus::Rest.destroy('/service/local/repositories/example')
      stub.should have_been_requested
    end

    it 'should send admin credentials' do
      stub = stub_request(:delete, /foobar:secret@example.com.*/).to_return(:status => 200)
      Nexus::Rest.destroy('/service/local/repositories/example')
      stub.should have_been_requested
    end

    it 'should raise an error if response is not expected' do
      stub_request(:delete, /.*/).to_return(:status => 503)
      expect {
        Nexus::Rest.destroy('/service/local/repositories/example')
      }.to raise_error(RuntimeError, /Failed to submit DELETE/)
    end
  end
end

describe Nexus::Config do
  describe 'read_config' do
    it 'should raise an error if file is not existing' do
      YAML.should_receive(:load_file).and_raise('file not found')
      expect { Nexus::Config.read_config }.to raise_error
    end
    it 'should raise an error if base url is missing' do
      YAML.should_receive(:load_file).and_return({'admin_username' => 'foobar', 'admin_password' => 'secret'})
      expect { Nexus::Config.read_config }.to raise_error
    end
    it 'should raise an error if admin username is missing' do
      YAML.should_receive(:load_file).and_return({'base_url' => 'http://example.com', 'admin_password' => 'secret'})
      expect { Nexus::Config.read_config }.to raise_error
    end
    it 'should raise an error if admin password is missing' do
      YAML.should_receive(:load_file).and_return({'base_url' => 'http://example.com', 'admin_username' => 'foobar'})
      expect { Nexus::Config.read_config }.to raise_error
    end
    it 'should read base url' do
      YAML.should_receive(:load_file).and_return({'base_url' => 'http://example.com', 'admin_username' => 'foobar', 'admin_password' => 'secret'})
      Nexus::Config.read_config[:base_url].should == 'http://example.com'
    end
    it 'should read admin username' do
      YAML.should_receive(:load_file).and_return({'base_url' => 'http://example.com', 'admin_username' => 'foobar', 'admin_password' => 'secret'})
      Nexus::Config.read_config[:admin_username].should == 'foobar'
    end
    it 'should read admin password' do
      YAML.should_receive(:load_file).and_return({'base_url' => 'http://example.com', 'admin_username' => 'foobar', 'admin_password' => 'secret'})
      Nexus::Config.read_config[:admin_password].should == 'secret'
    end
  end
end
