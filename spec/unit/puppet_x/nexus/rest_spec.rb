require 'puppet_x/nexus/config'
require 'puppet_x/nexus/exception'
require 'puppet_x/nexus/rest'
require 'spec_helper'
include WebMock::API

describe Nexus::Rest do
  before(:each) do
    Nexus::Config.stub(:read_config).and_return({
      :nexus_base_url => 'http://example.com',
      :admin_username => 'foobar',
      :admin_password => 'secret'
    })
  end

  before(:each) do
    # health check always successful ...
    service = double('Dummy service').as_null_object
    Nexus::Rest.stub(:init_service).and_return(service)
  end

  after(:each) do
    Nexus::Config.reset
  end

  describe :get_all do
    specify 'should parse JSON response' do
      stub_request(:any, /.*/).to_return(:body => '{ "data": [{"id": "repository-1"}, {"id": "repository-2"}] }')
      instances = Nexus::Rest.get_all('/service/local/repositories')
      expect(instances['data']).to have(2).items
    end

    specify 'should accept only application/json' do
      stub = stub_request(:get, /.*/).with(:headers => {'Accept' => 'application/json'}).to_return(:body => '{}')
      Nexus::Rest.get_all('/service/local/repositories')
      expect(stub).to have_been_requested
    end

    specify 'should send credentials' do
      stub = stub_request(:get, /foobar:secret@example.com.*/).to_return(:body => '{}')
      Nexus::Rest.get_all('/service/local/repositories')
      expect(stub).to have_been_requested
    end

    specify 'should raise an error if response is not expected' do
      stub_request(:any, /.*/).to_return(:status => 503)
      expect { Nexus::Rest.get_all('/service/local/repositories') }.to raise_error(RuntimeError, /Could not request/)
    end

    specify 'should raise an error if response is not parsable' do
      stub_request(:any, /.*/).to_return(:body => 'some non-json crap')
      expect { Nexus::Rest.get_all('/service/local/repositories') }.to raise_error(RuntimeError, /Could not parse the JSON/)
    end
  end

  describe :get_all_plus_n do
    specify 'should parse JSON response' do
      stub = stub_request(:any, /.*/).to_return(:body => '{ "data": [] }')
      instances = Nexus::Rest.get_all_plus_n('/service/local/repositories')
      expect(stub).to have_been_requested
    end

    specify 'should accept only application/json' do
      stub = stub_request(:get, /.*/).with(:headers => {'Accept' => 'application/json'}).to_return(:body => '{}')
      Nexus::Rest.get_all_plus_n('/service/local/repositories')
      expect(stub).to have_been_requested
    end

    specify 'should send credentials' do
      stub = stub_request(:get, /foobar:secret@example.com.*/).to_return(:body => '{}')
      Nexus::Rest.get_all_plus_n('/service/local/repositories')
      expect(stub).to have_been_requested
    end

    specify 'should raise an error if initial response is not expected' do
      stub_request(:any, /.*/).to_return(:status => 503)
      expect { Nexus::Rest.get_all_plus_n('/service/local/repositories') }.to raise_error(RuntimeError, /Could not request/)
    end

    specify 'should raise an error if initial response is not parsable' do
      stub_request(:any, /.*/).to_return(:body => 'some non-json crap')
      expect { Nexus::Rest.get_all_plus_n('/service/local/repositories') }.to raise_error(RuntimeError, /Could not parse the JSON/)
    end

    specify 'should resolve details of referenced resource' do
      stub_request(:get, /example.com\/service\/local\/repositories/).to_return(:body => '{ "data": [{"id": "repository-1"}] }')
      stub_request(:get, /example.com\/service\/local\/repositories\/repository-1/).to_return(:body => '{ "data": {"id": "repository-1", "name": "example"} }')
      instances = Nexus::Rest.get_all_plus_n('/service/local/repositories')
      instances['data'].should have(1).items
      expect(instances['data'][0]['id']).to eq('repository-1')
      expect(instances['data'][0]['name']).to eq('example')
    end

    specify 'should raise an error if referenced resource returns an expected response' do
      stub_request(:any, /example.com\/service\/local\/repositories/).to_return(:body => '{ "data": [{"id": "repository-1"}] }')
      stub_request(:any, /example.com\/service\/local\/repositories\/repository-1/).to_return(:status => 503)
      expect { Nexus::Rest.get_all_plus_n('/service/local/repositories') }.to raise_error(RuntimeError, /repository-1/)
    end

    specify 'should raise an error if referenced resource returns unparsable response' do
      stub_request(:any, /example.com\/service\/local\/repositories/).to_return(:body => '{ "data": [{"id": "repository-1"}] }')
      stub_request(:any, /example.com\/service\/local\/repositories\/repository-1/).to_return(:body => 'some non-json crap')
      expect { Nexus::Rest.get_all_plus_n('/service/local/repositories') }.to raise_error(RuntimeError, /repository-1/)
    end

    specify 'should return `data => []` even when the result is nil' do
      Nexus::Rest.stub(:get_all).and_return(nil)
      expect(Nexus::Rest.get_all_plus_n('/service/local/repositories')).to eq({'data' => []})
    end

    specify 'should return `data => []` when there are no results' do
      stub = stub_request(:any, /.*/).to_return(:body => '{ }')
      expect(Nexus::Rest.get_all_plus_n('/service/local/repositories')).to eq({'data' => []})
    end
  end

  describe :create do
    specify 'should submit a POST to /service/local/repositories' do
      stub = stub_request(:post, /example.com\/service\/local\/repositories/).to_return(:status => 200)
      Nexus::Rest.create('/service/local/repositories', {})
      expect(stub).to have_been_requested
    end

    specify 'should use content type application/json' do
      stub = stub_request(:post, /.*/).with(:headers => {'Content-Type' => 'application/json'}, :body => {}).to_return(:status => 200)
      Nexus::Rest.create('/service/local/repositories', {})
      expect(stub).to have_been_requested
    end

    specify 'should send credentials' do
      stub = stub_request(:post, /foobar:secret@example.com.*/).to_return(:status => 200)
      Nexus::Rest.create('/service/local/repositories', {'data' => {'id' => 'foobar'}})
      expect(stub).to have_been_requested
    end

    specify 'should submit the passed data' do
      stub = stub_request(:post, /.*/).with(:body => {:data => {:a => '1', :b => 'five'}}).to_return(:status => 200)
      Nexus::Rest.create('/service/local/repositories', {'data' => {:a => '1', :b => 'five'}})
      expect(stub).to have_been_requested
    end

    specify 'should raise an error if response is not expected' do
      stub_request(:any, /.*/).to_return(:status => 503)
      expect { Nexus::Rest.create('/service/local/repositories', {}) }.to raise_error(RuntimeError, /Could not create/)
    end

    specify 'should accept only application/json' do
      stub = stub_request(:any, /.*/).with(:headers => {'Accept' => 'application/json'}).to_return(:body => '{}')
      Nexus::Rest.create('/service/local/repositories', {})
      expect(stub).to have_been_requested
    end

    specify 'should extract error message' do
      stub = stub_request(:any, /.*/).to_return(:status => 400, :body => {'errors' => [{'id' => '*', 'msg' =>  'Error message'}]})
      expect { Nexus::Rest.create('/service/local/repositories', {}) }.to raise_error(RuntimeError, /Error message/)
    end
  end

  describe :update do
    specify 'should submit a PUT to /service/local/repositories/example' do
      stub = stub_request(:put, /example.com\/service\/local\/repositories/).to_return(:status => 200)
      Nexus::Rest.update('/service/local/repositories/example', {})
      expect(stub).to have_been_requested
    end

    specify 'should raise an error if response is not expected' do
      stub_request(:any, /.*/).to_return(:status => 503)
      expect { Nexus::Rest.update('/service/local/repositories/example', {}) }.to raise_error(RuntimeError, /Could not update/)
    end

    specify 'should accept only application/json' do
      stub = stub_request(:any, /.*/).with(:headers => {'Accept' => 'application/json'}).to_return(:body => '{}')
      Nexus::Rest.update('/service/local/repositories/example', {})
      expect(stub).to have_been_requested
    end

    specify 'should extract error message' do
      stub = stub_request(:any, /.*/).to_return(:status => 400, :body => {'errors' => [{'id' => '*', 'msg' =>  'Error message'}]})
      expect { Nexus::Rest.update('/service/local/repositories/example', {}) }.to raise_error(RuntimeError, /Error message/)
    end
  end

  describe :destroy do
    specify 'should submit a DELETE to /service/local/repositories/example' do
      stub = stub_request(:delete, /example.com\/service\/local\/repositories\/example/).to_return(:status => 200)
      Nexus::Rest.destroy('/service/local/repositories/example')
      expect(stub).to have_been_requested
    end

    specify 'should not fail if resource already deleted' do
      stub = stub_request(:delete, /.*/).to_return(:status => 404)
      Nexus::Rest.destroy('/service/local/repositories/example')
      expect(stub).to have_been_requested
    end

    specify 'should send credentials' do
      stub = stub_request(:delete, /foobar:secret@example.com.*/).to_return(:status => 200)
      Nexus::Rest.destroy('/service/local/repositories/example')
      expect(stub).to have_been_requested
    end

    specify 'should raise an error if response is not expected' do
      stub_request(:delete, /.*/).to_return(:status => 503)
      expect { Nexus::Rest.destroy('/service/local/repositories/example') }.to raise_error(RuntimeError, /Could not delete/)
    end

    specify 'should accept only application/json' do
      stub = stub_request(:any, /.*/).with(:headers => {'Accept' => 'application/json'}).to_return(:body => '{}')
      Nexus::Rest.destroy('/service/local/repositories/example')
      expect(stub).to have_been_requested
    end

    specify 'should extract error message' do
      stub = stub_request(:any, /.*/).to_return(:status => 400, :body => {'errors' => [{'id' => '*', 'msg' =>  'Error message'}]})
      expect { Nexus::Rest.destroy('/service/local/repositories/example') }.to raise_error(RuntimeError, /Error message/)
    end
  end
end
