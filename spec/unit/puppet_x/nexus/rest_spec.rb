require 'spec_helper'
include WebMock::API

describe Nexus::Rest do
  before(:each) do
    Nexus::Config.stub(:read_config).and_return({
      :base_url       => 'http://example.com',
      :username => 'foobar',
      :password => 'secret'
    })
  end

  after(:each) do
    Nexus::Config.reset
  end

  describe 'get_all' do
    it 'should parse JSON response' do
      stub_request(:any, /.*/).to_return(:body => '{ "data": [{"id": "repository-1"}, {"id": "repository-2"}] }')
      instances = Nexus::Rest.get_all('/service/local/repositories')
      instances['data'].should have(2).items
    end

    it 'should accept only application/json' do
      stub = stub_request(:get, /.*/).with(:headers => {'Accept' => 'application/json'}).to_return(:body => '{}')
      Nexus::Rest.get_all('/service/local/repositories')
      stub.should have_been_requested
    end

    it 'should send credentials' do
      stub = stub_request(:get, /foobar:secret@example.com.*/).to_return(:body => '{}')
      Nexus::Rest.get_all('/service/local/repositories')
      stub.should have_been_requested
    end

    it 'should raise an error if response is not expected' do
      stub_request(:any, /.*/).to_return(:status => 503)
      expect {
        Nexus::Rest.get_all('/service/local/repositories')
      }.to raise_error(RuntimeError, /Could not request/)
    end

    it 'should raise an error if response is not parsable' do
      stub_request(:any, /.*/).to_return(:body => 'some non-json crap')
      expect {
        Nexus::Rest.get_all('/service/local/repositories')
      }.to raise_error(RuntimeError, /Could not parse the JSON/)
    end
  end

  describe 'get_all_plus_n' do
    it 'should parse JSON response' do
      stub = stub_request(:any, /.*/).to_return(:body => '{ "data": [] }')
      instances = Nexus::Rest.get_all_plus_n('/service/local/repositories')
      stub.should have_been_requested
    end

    it 'should accept only application/json' do
      stub = stub_request(:get, /.*/).with(:headers => {'Accept' => 'application/json'}).to_return(:body => '{}')
      Nexus::Rest.get_all_plus_n('/service/local/repositories')
      stub.should have_been_requested
    end

    it 'should send credentials' do
      stub = stub_request(:get, /foobar:secret@example.com.*/).to_return(:body => '{}')
      Nexus::Rest.get_all_plus_n('/service/local/repositories')
      stub.should have_been_requested
    end

    it 'should raise an error if initial response is not expected' do
      stub_request(:any, /.*/).to_return(:status => 503)
      expect {
        Nexus::Rest.get_all_plus_n('/service/local/repositories')
      }.to raise_error(RuntimeError, /Could not request/)
    end

    it 'should raise an error if initial response is not parsable' do
      stub_request(:any, /.*/).to_return(:body => 'some non-json crap')
      expect {
        Nexus::Rest.get_all_plus_n('/service/local/repositories')
      }.to raise_error(RuntimeError, /Could not parse the JSON/)
    end

    it 'should resolve details of referenced resource' do
      stub_request(:get, /example.com\/service\/local\/repositories/).to_return(:body => '{ "data": [{"id": "repository-1"}] }')
      stub_request(:get, /example.com\/service\/local\/repositories\/repository-1/).to_return(:body => '{ "data": {"id": "repository-1", "name": "example"} }')
      instances = Nexus::Rest.get_all_plus_n('/service/local/repositories')
      instances['data'].should have(1).items
      expect(instances['data'][0]['id']).to eq('repository-1')
      expect(instances['data'][0]['name']).to eq('example')
    end

    it 'should raise an error if referenced resource returns an expected response' do
      stub_request(:any, /example.com\/service\/local\/repositories/).to_return(:body => '{ "data": [{"id": "repository-1"}] }')
      stub_request(:any, /example.com\/service\/local\/repositories\/repository-1/).to_return(:status => 503)
      expect {
        Nexus::Rest.get_all_plus_n('/service/local/repositories')
      }.to raise_error(RuntimeError, /repository-1/)
    end

    it 'should raise an error if referenced resource returns unparsable response' do
      stub_request(:any, /example.com\/service\/local\/repositories/).to_return(:body => '{ "data": [{"id": "repository-1"}] }')
      stub_request(:any, /example.com\/service\/local\/repositories\/repository-1/).to_return(:body => 'some non-json crap')
      expect {
        Nexus::Rest.get_all_plus_n('/service/local/repositories')
      }.to raise_error(RuntimeError, /repository-1/)
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

    it 'should send credentials' do
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
      }.to raise_error(RuntimeError, /Could not create/)
    end

    it 'should accept only application/json' do
      stub = stub_request(:any, /.*/).with(:headers => {'Accept' => 'application/json'}).to_return(:body => '{}')
      Nexus::Rest.create('/service/local/repositories', {})
      stub.should have_been_requested
    end

    it 'should extract error message' do
      stub = stub_request(:any, /.*/).to_return(:status => 400, :body => {:errors => [{:id => '*', :msg =>  'Error message'}]})
      expect { Nexus::Rest.create('/service/local/repositories', {}) }.to raise_error(RuntimeError, /Error message/)
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
      }.to raise_error(RuntimeError, /Could not update/)
    end

    it 'should accept only application/json' do
      stub = stub_request(:any, /.*/).with(:headers => {'Accept' => 'application/json'}).to_return(:body => '{}')
      Nexus::Rest.update('/service/local/repositories/example', {})
      stub.should have_been_requested
    end

    it 'should extract error message' do
      stub = stub_request(:any, /.*/).to_return(:status => 400, :body => {:errors => [{:id => '*', :msg =>  'Error message'}]})
      expect { Nexus::Rest.update('/service/local/repositories/example', {}) }.to raise_error(RuntimeError, /Error message/)
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

    it 'should send credentials' do
      stub = stub_request(:delete, /foobar:secret@example.com.*/).to_return(:status => 200)
      Nexus::Rest.destroy('/service/local/repositories/example')
      stub.should have_been_requested
    end

    it 'should raise an error if response is not expected' do
      stub_request(:delete, /.*/).to_return(:status => 503)
      expect {
        Nexus::Rest.destroy('/service/local/repositories/example')
      }.to raise_error(RuntimeError, /Could not delete/)
    end

    it 'should accept only application/json' do
      stub = stub_request(:any, /.*/).with(:headers => {'Accept' => 'application/json'}).to_return(:body => '{}')
      Nexus::Rest.destroy('/service/local/repositories/example')
      stub.should have_been_requested
    end

    it 'should extract error message' do
      stub = stub_request(:any, /.*/).to_return(:status => 400, :body => {:errors => [{:id => '*', :msg =>  'Error message'}]})
      expect { Nexus::Rest.destroy('/service/local/repositories/example') }.to raise_error(RuntimeError, /Error message/)
    end
  end
end
