require 'puppet_x/nexus/config'
require 'spec_helper'

describe Nexus::Config do

  let(:nexus_base_url) { 'http://example.com' }
  let(:admin_username) { 'foobar' }
  let(:admin_password) { 'secret' }
  let(:url_and_credentials) { {'base_url' => nexus_base_url, 'username' => admin_username, 'password' => admin_password} }

  after(:each) do
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

    specify 'should raise an error if base url is missing' do
      YAML.should_receive(:load_file).and_return(url_and_credentials.reject{|key,value| key == 'base_url'})
      expect { Nexus::Config.read_config }.to raise_error(Puppet::ParseError, /must contain a value for key 'base_url'/)
    end

    specify 'should raise an error if username is missing' do
      YAML.should_receive(:load_file).and_return(url_and_credentials.reject{|key,value| key == 'username'})
      expect { Nexus::Config.read_config }.to raise_error(Puppet::ParseError, /must contain a value for key 'username'/)
    end

    specify 'should raise an error if password is missing' do
      YAML.should_receive(:load_file).and_return(url_and_credentials.reject{|key,value| key == 'password'})
      expect { Nexus::Config.read_config }.to raise_error(Puppet::ParseError, /must contain a value for key 'password'/)
    end

    specify 'should read base url' do
      YAML.should_receive(:load_file).and_return(url_and_credentials)
      expect(Nexus::Config.read_config[:base_url]).to eq(nexus_base_url)
    end

    specify 'should read username' do
      YAML.should_receive(:load_file).and_return(url_and_credentials)
      expect(Nexus::Config.read_config[:username]).to eq(admin_username)
    end

    specify 'should read password' do
      YAML.should_receive(:load_file).and_return(url_and_credentials)
      expect(Nexus::Config.read_config[:password]).to eq(admin_password)
    end

    specify 'should use default timeout if not specified' do
      YAML.should_receive(:load_file).and_return(url_and_credentials)
      expect(Nexus::Config.read_config[:timeout]).to be(10)
    end

    specify 'should read timeout' do
      YAML.should_receive(:load_file).and_return(url_and_credentials.merge({'timeout' => '60'}))
      expect(Nexus::Config.read_config[:timeout]).to be(60)
    end

    specify 'should use default open timeout if not specified' do
      YAML.should_receive(:load_file).and_return(url_and_credentials)
      expect(Nexus::Config.read_config[:timeout]).to be(10)
    end

    specify 'should read open timeout' do
      YAML.should_receive(:load_file).and_return(url_and_credentials.merge({'open_timeout' => '60'}))
      expect(Nexus::Config.read_config[:open_timeout]).to be(60)
    end
  end

  describe :resolve do
    specify 'should add base url to absolute url' do
      YAML.should_receive(:load_file).and_return(url_and_credentials)
      expect(Nexus::Config.resolve('/foobar')).to eq("#{nexus_base_url}/foobar")
    end

    specify 'should add base url to relative url' do
      YAML.should_receive(:load_file).and_return(url_and_credentials)
      expect(Nexus::Config.resolve('foobar')).to eq("#{nexus_base_url}/foobar")
    end

    specify 'should not add base url if the url starts with http' do
      expect(Nexus::Config.resolve('http://somewhere.else/foobar')).to eq('http://somewhere.else/foobar')
    end

    specify 'should not add base url if the url starts with https' do
      expect(Nexus::Config.resolve('https://secure.net/foobar')).to eq('https://secure.net/foobar')
    end
  end
end
