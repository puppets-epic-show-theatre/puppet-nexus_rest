require 'spec_helper'
include WebMock::API

describe Nexus::Rest do
  describe 'instances' do
    let :instances do
      Nexus::Config.should_receive(:base_url).and_return('http://example.com')
      stub_request(:any, 'example.com/service/local/repositories').to_return(:body => '{ "data": [{"id": "repository-1"}, {"id": "repository-2"}] }')
      Nexus::Rest.get_all('/service/local/repositories')
    end

    it { instances['data'].should have(2).items }
  end

  describe 'create' do
    it 'should submit a POST to /service/local/repositories' do
      Nexus::Config.should_receive(:base_url).and_return('http://example.com')
      stub = stub_request(:post, 'example.com/service/local/repositories').to_return(:status => 200)
      Nexus::Rest.create('/service/local/repositories')
      stub.should have_been_requested
    end

    it 'should raise an error if response is not expected' do
      Nexus::Config.should_receive(:base_url).and_return('http://example.com')
      stub_request(:any, 'example.com/service/local/repositories').to_return(:status => 503)
      expect {
        Nexus::Rest.create('/service/local/repositories')
      }.to raise_error
    end
  end

  describe 'update' do
    it 'should submit a PUT to /service/local/repositories/example' do
      Nexus::Config.should_receive(:base_url).and_return('http://example.com')
      stub = stub_request(:put, 'example.com/service/local/repositories/example').to_return(:status => 200)
      Nexus::Rest.update('/service/local/repositories/example')
      stub.should have_been_requested
    end

    it 'should raise an error if response is not expected' do
      Nexus::Config.should_receive(:base_url).and_return('http://example.com')
      stub_request(:any, 'example.com/service/local/repositories/example').to_return(:status => 503)
      expect {
        Nexus::Rest.update('/service/local/repositories/example')
      }.to raise_error
    end
  end

  describe 'destroy' do
    it 'should submit a DELETE to /service/local/repositories/example' do
      Nexus::Config.should_receive(:base_url).and_return('http://example.com')
      stub = stub_request(:delete, 'example.com/service/local/repositories/example').to_return(:status => 200)
      Nexus::Rest.destroy('/service/local/repositories/example')
      stub.should have_been_requested
    end

    it 'should not fail if resource already deleted' do
      Nexus::Config.should_receive(:base_url).and_return('http://example.com')
      stub = stub_request(:delete, 'example.com/service/local/repositories/example').to_return(:status => 404)
      Nexus::Rest.destroy('/service/local/repositories/example')
      stub.should have_been_requested
    end

    it 'should raise an error if response is not expected' do
      Nexus::Config.should_receive(:base_url).and_return('http://example.com')
      stub_request(:delete, 'example.com/service/local/repositories/example').to_return(:status => 503)
      expect {
        Nexus::Rest.destroy('/service/local/repositories/example')
      }.to raise_error
    end
  end

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
      YAML.should_receive(:load_file).and_return({'baseurl' => 'http://example.com', 'admin_password' => 'secret'})
      expect { Nexus::Config.read_config }.to raise_error
    end
    it 'should raise an error if admin password is missing' do
      YAML.should_receive(:load_file).and_return({'baseurl' => 'http://example.com', 'admin_username' => 'foobar'})
      expect { Nexus::Config.read_config }.to raise_error
    end
    it 'should read base url' do
      YAML.should_receive(:load_file).and_return({'baseurl' => 'http://example.com', 'admin_username' => 'foobar', 'admin_password' => 'secret'})
      Nexus::Config.read_config['baseurl'].should == 'http://example.com'
    end
    it 'should read admin username' do
      YAML.should_receive(:load_file).and_return({'baseurl' => 'http://example.com', 'admin_username' => 'foobar', 'admin_password' => 'secret'})
      Nexus::Config.read_config['admin_username'].should == 'foobar'
    end
    it 'should read admin password' do
      YAML.should_receive(:load_file).and_return({'baseurl' => 'http://example.com', 'admin_username' => 'foobar', 'admin_password' => 'secret'})
      Nexus::Config.read_config['admin_password'].should == 'secret'
    end
  end
end
