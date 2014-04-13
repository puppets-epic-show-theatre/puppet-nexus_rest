require 'spec_helper'

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
