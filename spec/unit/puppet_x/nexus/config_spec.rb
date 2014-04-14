require 'spec_helper'

describe Nexus::Config do
  after(:each) do
    Nexus::Config.reset
  end

  describe 'read_config' do
    it 'should raise an error if file is not existing' do
      YAML.should_receive(:load_file).and_raise('file not found')
      expect { Nexus::Config.read_config }.to raise_error
    end
    it 'should raise an error if base url is missing' do
      YAML.should_receive(:load_file).and_return({'username' => 'foobar', 'password' => 'secret'})
      expect { Nexus::Config.read_config }.to raise_error
    end
    it 'should raise an error if username is missing' do
      YAML.should_receive(:load_file).and_return({'base_url' => 'http://example.com', 'password' => 'secret'})
      expect { Nexus::Config.read_config }.to raise_error
    end
    it 'should raise an error if password is missing' do
      YAML.should_receive(:load_file).and_return({'base_url' => 'http://example.com', 'username' => 'foobar'})
      expect { Nexus::Config.read_config }.to raise_error
    end
    it 'should read base url' do
      YAML.should_receive(:load_file).and_return({'base_url' => 'http://example.com', 'username' => 'foobar', 'password' => 'secret'})
      Nexus::Config.read_config[:base_url].should == 'http://example.com'
    end
    it 'should read username' do
      YAML.should_receive(:load_file).and_return({'base_url' => 'http://example.com', 'username' => 'foobar', 'password' => 'secret'})
      Nexus::Config.read_config[:username].should == 'foobar'
    end
    it 'should read password' do
      YAML.should_receive(:load_file).and_return({'base_url' => 'http://example.com', 'username' => 'foobar', 'password' => 'secret'})
      Nexus::Config.read_config[:password].should == 'secret'
    end
  end

  describe 'resolve' do
    it 'should add base url to absolute url' do
      YAML.should_receive(:load_file).and_return({'base_url' => 'http://example.com', 'username' => 'foobar', 'password' => 'secret'})
      Nexus::Config.resolve('/foobar').should == 'http://example.com/foobar'
    end
    it 'should add base url to relative url' do
      YAML.should_receive(:load_file).and_return({'base_url' => 'http://example.com', 'username' => 'foobar', 'password' => 'secret'})
      Nexus::Config.resolve('foobar').should == 'http://example.com/foobar'
    end
    it 'should not add base url if the url starts with http' do
      Nexus::Config.resolve('http://somewhere.else/foobar').should == 'http://somewhere.else/foobar'
    end
    it 'should not add base url if the url starts with https' do
      Nexus::Config.resolve('https://secure.net/foobar').should == 'https://secure.net/foobar'
    end
  end
end
