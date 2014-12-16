require 'puppet_x/nexus/service'
require 'spec_helper'

describe Nexus::Service do
  let(:configuration) do
    {
      :nexus_base_url       => 'http://example.com',
      :admin_username       => 'foobar',
      :admin_password       => 'secret',
      :health_check_retries => 3,
      :health_check_timeout => 0,
    }
  end

  describe 'HealthCheckClient.check_health' do
    let(:client) { Nexus::Service::HealthCheckClient.new(configuration) }

    specify 'should talk to /service/local/status' do
      stub = stub_request(:any, /example.com\/service\/local\/status/).to_return(:status => 200)
      client.check_health
      expect(stub).to have_been_requested
    end

    specify 'should report running if the instance is up' do
      stub_request(:any, /.*/).to_return(:body => '{ "data": { "state": "STARTED" } }')
      expect(client.check_health.status).to eq(:running)
    end

    specify 'should report broken if the instance failed to start up' do
      stub_request(:any, /.*/).to_return(:body => '{ "data": { "state": "BROKEN_CONFIGURATION" } }')
      expect(client.check_health.status).to eq(:broken)
    end

    specify 'should report an error message' do
      stub_request(:any, /.*/).to_return(:body => '{ "data": { "state": "BROKEN_CONFIGURATION", "errorCause": "Something was wrong" } }')
      expect(client.check_health.log_message).to match(/Something was wrong/)
    end

    specify 'should report not running if the instance is still starting up' do
      stub_request(:any, /.*/).to_return(:body => '{ "data": { "state": "STARTING" } }')
      expect(client.check_health.status).to eq(:not_running)
      expect(client.check_health.log_message).to match(/Nexus service is not running, yet./)
    end
  end

  describe 'CachingService.ensure_running' do
    let(:delegatee) { double('The real service') }
    let(:service) { Nexus::CachingService.new(delegatee) }

    specify 'should delegate to the real service' do
      delegatee.should_receive(:ensure_running).and_return()
      expect { service.ensure_running }.to_not raise_error
    end

    specify 'should not cache successful result' do
      delegatee.should_receive(:ensure_running).exactly(2).times.and_return()
      service.ensure_running
      expect { service.ensure_running }.to_not raise_error
    end

    specify 'should cache a negative result' do
      delegatee.should_receive(:ensure_running).exactly(1).times.and_raise('service is borked')
      expect { service.ensure_running }.to raise_error(RuntimeError, /service is borked/)
      expect { service.ensure_running }.to raise_error(RuntimeError, /Nexus service failed a previous health check/)
    end
  end

  describe :ensure_running do
    let(:client) { double('Dummy Health Check Client') }
    let(:service) { Nexus::Service.new(client, configuration) }

    specify 'should retry if service is not running' do
      client.should_receive(:check_health).and_return(Nexus::Service::Status.not_running('still starting'), Nexus::Service::Status.running)
      expect { service.ensure_running }.to_not raise_error
    end

    specify 'should bail out immediately if the service is broken' do
      client.should_receive(:check_health).and_return(Nexus::Service::Status.broken('service is borked'))
      expect { service.ensure_running }.to raise_error(RuntimeError, /service is borked/)
    end

    specify "should retry no more than configured" do
      client.should_receive(:check_health).at_most(configuration[:health_check_retries]).times.and_return(Nexus::Service::Status.not_running('still starting'))
      expect { service.ensure_running }.to raise_error(RuntimeError, /Nexus service did not start up within 0 seconds/)
    end
  end
end
