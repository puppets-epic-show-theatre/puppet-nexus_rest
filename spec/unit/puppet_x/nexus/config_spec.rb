require 'puppet_x/nexus/config'
require 'spec_helper'

describe Nexus::Config do

  let(:nexus_base_url) { 'http://example.com' }
  let(:admin_username) { 'foobar' }
  let(:admin_password) { 'secret' }
  let(:base_url_and_credentials) do
    {
      'nexus_base_url'          => nexus_base_url,
      'admin_username'          => admin_username,
      'admin_password'          => admin_password,
      'can_delete_repositories' => false,
    }
  end

  before(:each) do
    Nexus::Config.reset
  end

  describe :file_path do
    specify 'should retrieve path to Puppet\'s configuration directory from the API' do
      Puppet.settings[:confdir] = '/puppet/is/somewhere/else'
      expect(Nexus::Config.file_path).to eq('/puppet/is/somewhere/else/nexus_rest.conf')
    end

    specify 'should cache the filename' do
      expect(Nexus::Config.file_path).to be(Nexus::Config.file_path)
    end
  end

  describe :read_config do
    specify 'should raise an error if file is not existing' do
      YAML.should_receive(:load_file).and_raise('file not found')
      expect { Nexus::Config.read_config }.to raise_error(Puppet::ParseError, /file not found/)
    end

    specify 'should raise an error if Nexus base url is missing' do
      YAML.should_receive(:load_file).and_return(base_url_and_credentials.reject{|key,value| key == 'nexus_base_url'})
      expect { Nexus::Config.read_config }.to raise_error(Puppet::ParseError, /must contain a value for key 'nexus_base_url'/)
    end

    specify 'should raise an error if admin username is missing' do
      YAML.should_receive(:load_file).and_return(base_url_and_credentials.reject{|key,value| key == 'admin_username'})
      expect { Nexus::Config.read_config }.to raise_error(Puppet::ParseError, /must contain a value for key 'admin_username'/)
    end

    specify 'should raise an error if admin password is missing' do
      YAML.should_receive(:load_file).and_return(base_url_and_credentials.reject{|key,value| key == 'admin_password'})
      expect { Nexus::Config.read_config }.to raise_error(Puppet::ParseError, /must contain a value for key 'admin_password'/)
    end

    specify 'should read Nexus base url' do
      YAML.should_receive(:load_file).and_return(base_url_and_credentials)
      expect(Nexus::Config.read_config[:nexus_base_url]).to eq(nexus_base_url)
    end

    specify 'should read admin username' do
      YAML.should_receive(:load_file).and_return(base_url_and_credentials)
      expect(Nexus::Config.read_config[:admin_username]).to eq(admin_username)
    end

    specify 'should read admin password' do
      YAML.should_receive(:load_file).and_return(base_url_and_credentials)
      expect(Nexus::Config.read_config[:admin_password]).to eq(admin_password)
    end

    specify 'should raise an error if can_delete_repositories flag is missing' do
      YAML.should_receive(:load_file).and_return(base_url_and_credentials.reject{|key,value| key == 'can_delete_repositories'})
      expect { Nexus::Config.read_config }.to raise_error(Puppet::ParseError, /must contain a value for key 'can_delete_repositories'/)
    end

    specify 'should read can_delete_repositories flag (false case)' do
      YAML.should_receive(:load_file).and_return(base_url_and_credentials.merge({'can_delete_repositories' => false}))
      expect(Nexus::Config.read_config[:can_delete_repositories]).to be_false
    end

    specify 'should read can_delete_repositories flag (true case)' do
      YAML.should_receive(:load_file).and_return(base_url_and_credentials.merge({'can_delete_repositories' => true}))
      expect(Nexus::Config.read_config[:can_delete_repositories]).to be_true
    end

    specify 'should use default connection timeout if not specified' do
      YAML.should_receive(:load_file).and_return(base_url_and_credentials)
      expect(Nexus::Config.read_config[:connection_timeout]).to be(10)
    end

    specify 'should read connection timeout' do
      YAML.should_receive(:load_file).and_return(base_url_and_credentials.merge({'connection_timeout' => '60'}))
      expect(Nexus::Config.read_config[:connection_timeout]).to be(60)
    end

    specify 'should use default connection open timeout if not specified' do
      YAML.should_receive(:load_file).and_return(base_url_and_credentials)
      expect(Nexus::Config.read_config[:connection_timeout]).to be(10)
    end

    specify 'should read connection open timeout' do
      YAML.should_receive(:load_file).and_return(base_url_and_credentials.merge({'connection_open_timeout' => '60'}))
      expect(Nexus::Config.read_config[:connection_open_timeout]).to be(60)
    end

    specify 'should use default health check retries if not specified' do
      YAML.should_receive(:load_file).and_return(base_url_and_credentials)
      expect(Nexus::Config.read_config[:health_check_retries]).to be(50)
    end

    specify 'should read health check retries' do
      YAML.should_receive(:load_file).and_return(base_url_and_credentials.merge({'health_check_retries' => '100'}))
      expect(Nexus::Config.read_config[:health_check_retries]).to be(100)
    end

    specify 'should use default health check timeout if not specified' do
      YAML.should_receive(:load_file).and_return(base_url_and_credentials)
      expect(Nexus::Config.read_config[:health_check_timeout]).to be(3)
    end

    specify 'should read health check timeout' do
      YAML.should_receive(:load_file).and_return(base_url_and_credentials.merge({'health_check_timeout' => '10'}))
      expect(Nexus::Config.read_config[:health_check_timeout]).to be(10)
    end
  end

  describe :resolve do
    specify 'should add base url to absolute url' do
      YAML.should_receive(:load_file).and_return(base_url_and_credentials)
      expect(Nexus::Config.resolve('/foobar')).to eq("#{nexus_base_url}/foobar")
    end

    specify 'should add base url to relative url' do
      YAML.should_receive(:load_file).and_return(base_url_and_credentials)
      expect(Nexus::Config.resolve('foobar')).to eq("#{nexus_base_url}/foobar")
    end

    specify 'should not add base url if the url starts with http' do
      expect(Nexus::Config.resolve('http://somewhere.else/foobar')).to eq('http://somewhere.else/foobar')
    end

    specify 'should not add base url if the url starts with https' do
      expect(Nexus::Config.resolve('https://secure.net/foobar')).to eq('https://secure.net/foobar')
    end
  end

  describe :can_delete_repositories do
    specify 'should return false if can_delete_repositories configuration parameter is set to false' do
      YAML.should_receive(:load_file).and_return(base_url_and_credentials)
      expect(Nexus::Config.can_delete_repositories).to be_false
    end

    specify 'should return true if can_delete_repositories configuration parameter is set to true' do
      YAML.should_receive(:load_file).and_return(base_url_and_credentials.merge({'can_delete_repositories' => true}))
      expect(Nexus::Config.can_delete_repositories).to be_true
    end

    specify 'should return false if can_delete_repositories is some random crap' do
      YAML.should_receive(:load_file).and_return(base_url_and_credentials.merge({'can_delete_repositories' => 'We are the champions!'}))
      expect(Nexus::Config.can_delete_repositories).to be_false
    end
  end
end
