require 'puppet_x/nexus/config'
require 'spec_helper'

describe Nexus::Config do
  after(:each) do
    Nexus::Config.reset
  end

  describe :config_filename do
    specify 'should retrieve path to Puppet\'s configuration directory from the API' do
      Puppet.settings[:confdir] = '/puppet/is/somewhere/else'
      expect(Nexus::Config.filename).to eq('/puppet/is/somewhere/else/nexus_rest.conf')
    end

    specify 'should cache the filename' do
      expect(Nexus::Config.filename).to be(Nexus::Config.filename)
    end
  end

  describe :read_config do
    specify 'should raise an error if file is not existing' do
      YAML.should_receive(:load_file).and_raise('file not found')
      expect { Nexus::Config.read_config }.to raise_error
    end

    specify 'should raise an error if base url is missing' do
      YAML.should_receive(:load_file).and_return({'username' => 'foobar', 'password' => 'secret'})
      expect { Nexus::Config.read_config }.to raise_error
    end

    specify 'should raise an error if username is missing' do
      YAML.should_receive(:load_file).and_return({'base_url' => 'http://example.com', 'password' => 'secret'})
      expect { Nexus::Config.read_config }.to raise_error
    end

    specify 'should raise an error if password is missing' do
      YAML.should_receive(:load_file).and_return({'base_url' => 'http://example.com', 'username' => 'foobar'})
      expect { Nexus::Config.read_config }.to raise_error
    end

    specify 'should read base url' do
      YAML.should_receive(:load_file).and_return({'base_url' => 'http://example.com', 'username' => 'foobar', 'password' => 'secret'})
      expect(Nexus::Config.read_config[:base_url]).to eq('http://example.com')
    end

    specify 'should read username' do
      YAML.should_receive(:load_file).and_return({'base_url' => 'http://example.com', 'username' => 'foobar', 'password' => 'secret'})
      expect(Nexus::Config.read_config[:username]).to eq('foobar')
    end

    specify 'should read password' do
      YAML.should_receive(:load_file).and_return({'base_url' => 'http://example.com', 'username' => 'foobar', 'password' => 'secret'})
      expect(Nexus::Config.read_config[:password]).to eq('secret')
    end

    specify 'should use default timeout if not specified' do
      YAML.should_receive(:load_file).and_return({'base_url' => 'http://example.com', 'username' => 'foobar', 'password' => 'secret'})
      expect(Nexus::Config.read_config[:timeout]).to be(10)
    end

    specify 'should read timeout' do
      YAML.should_receive(:load_file).and_return({'base_url' => 'http://example.com', 'username' => 'foobar', 'password' => 'secret', 'timeout' => '60'})
      expect(Nexus::Config.read_config[:timeout]).to be(60)
    end

    specify 'should use default open timeout if not specified' do
      YAML.should_receive(:load_file).and_return({'base_url' => 'http://example.com', 'username' => 'foobar', 'password' => 'secret'})
      expect(Nexus::Config.read_config[:timeout]).to be(10)
    end

    specify 'should read open timeout' do
      YAML.should_receive(:load_file).and_return({'base_url' => 'http://example.com', 'username' => 'foobar', 'password' => 'secret', 'open_timeout' => '60'})
      expect(Nexus::Config.read_config[:open_timeout]).to be(60)
    end
  end

  describe :resolve do
    specify 'should add base url to absolute url' do
      YAML.should_receive(:load_file).and_return({'base_url' => 'http://example.com', 'username' => 'foobar', 'password' => 'secret'})
      expect(Nexus::Config.resolve('/foobar')).to eq('http://example.com/foobar')
    end

    specify 'should add base url to relative url' do
      YAML.should_receive(:load_file).and_return({'base_url' => 'http://example.com', 'username' => 'foobar', 'password' => 'secret'})
      expect(Nexus::Config.resolve('foobar')).to eq('http://example.com/foobar')
    end

    specify 'should not add base url if the url starts with http' do
      expect(Nexus::Config.resolve('http://somewhere.else/foobar')).to eq('http://somewhere.else/foobar')
    end

    specify 'should not add base url if the url starts with https' do
      expect(Nexus::Config.resolve('https://secure.net/foobar')).to eq('https://secure.net/foobar')
    end
  end
end
