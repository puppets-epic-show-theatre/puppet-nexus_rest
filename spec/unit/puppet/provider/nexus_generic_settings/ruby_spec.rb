require 'spec_helper'

describe Puppet::Type.type(:nexus_generic_settings).provider(:ruby) do
  before(:each) do
    Nexus::Config.stub(:resolve).and_return('http://example.com/foobar')
    config = {
            'data' => {
              'object_id' => 'foo',
              'title'     => 'bar'
              }
            }
    Nexus::Rest.stub(:get_all).and_return(config)

    Nexus::Rest.stub(:create)
    Nexus::Rest.stub(:update)
  end

  describe 'self.get_current_config' do
    resource = { :api_url_fragment => '/here' }
    specify 'should call api_url_fragment' do
      Nexus::Rest.should_receive(:get_all).with('/here')
      expect(described_class.get_current_config(resource)).to have(2).items
    end
    specify 'should raise a human readable error message if the operation failed' do
      Nexus::Rest.should_receive(:get_all).and_raise('Operation failed')
      expect { described_class.get_current_config(resource)}.to raise_error(Puppet::Error, /Error while retrieving generic configuration /)
    end
  end

  describe 'update_config' do

    def update_config(resource, config)
      instance = described_class.new()
      instance.resource = resource
      instance.update_config(config)
    end

    config = {}

    specify 'should create on api_url_fragment if action is create' do
      resource = { :api_url_fragment => '/here', :action => :create }
      Nexus::Rest.should_receive(:create).with('/here', anything())
      update_config(resource, config)
    end
    specify 'should update on api_url_fragment if action is update' do
      resource = { :api_url_fragment => '/here', :action => :update }
      Nexus::Rest.should_receive(:update).with('/here', anything())
      update_config(resource, config)
    end
    specify 'should raise a human readable error message if the operation failed' do
      resource = { :api_url_fragment => '/here', :action => :update }
      Nexus::Rest.should_receive(:update).and_raise('Operation failed')
      expect { update_config(resource, config ) }.to raise_error(Puppet::Error, /Error while updating generic configuration /)
    end
  end

  describe 'self.map_config_to_resource_hash' do
    specify 'should wrap config as :settings_hash' do
      config = { :foo => 'bar'}
      resource = described_class.map_config_to_resource_hash(config)
      expect(resource[:settings_hash]).to equal(config)
    end
  end

  describe 'map_resource_to_config' do
    def map(newHash, merge)
      instance = described_class.new()
      instance.resource = {
        :settings_hash => newHash,
        :merge         => merge
      }
      instance.map_resource_to_config
    end

    specify 'should convert numbers as strings to numbers' do
      newHash = { 'num' => "1" }
      result = map(newHash, false)
      expect(result['num']).to equal(1)
    end

    specify 'should merge if asked to' do
      newHash = { 'new_field' => "newvalue" }
      result = map(newHash, true)
      expect(result['new_field']).to eq("newvalue")
      expect(result['title']).to eq("bar")
      expect(result['object_id']).to eq("foo")
    end

    specify 'new value should overwrite old if merging' do
      newHash = { 'title' => "newvalue" }
      result = map(newHash, true)
      expect(result['title']).to eq("newvalue")
    end

    specify 'should not merge if not asked to' do
      newHash = { 'new_field' => "newvalue" }
      result = map(newHash, false)
      expect(result['new_field']).to eq("newvalue")
      expect(result['title']).to be_nil
      expect(result['object_id']).to be_nil
    end

  end

  describe 'self.instances' do
    resource = { :api_url_fragment => '/here' }
    specify { expect(described_class.instances(resource)).to have(1).items }
    specify 'should raise a human readable error message if the operation failed' do
      Nexus::Rest.should_receive(:get_all).and_raise('Operation failed')
      expect { described_class.instances(resource) }.to raise_error(Puppet::Error, /Error while retrieving generic configuration/)
    end
  end

  describe 'flush' do
    def flush(newHash, action, id_field)
      resource = {
        :action           => action,
        :settings_hash    => newHash,
        :id_field         => id_field,
        :merge            => false,
        :api_url_fragment => '/here'
      }
      instance = described_class.new()
      instance.resource = resource
      instance.flush()
    end

    specify 'should call update if in update mode and config has changed' do
      newHash = {
        'object_id' => 'foo',
        'title'     => 'barbar'
      }
      Nexus::Rest.should_receive(:update).with('/here', anything())
      Nexus::Rest.should_not_receive(:create)
      flush(newHash, :update, 'object_id')
    end
    specify 'should not call update if in update mode and config has not changed' do
      newHash = {
        'object_id' => 'foo',
        'title'     => 'bar'
      }
      Nexus::Rest.should_not_receive(:update)
      Nexus::Rest.should_not_receive(:create)
      flush(newHash, :update, 'object_id')
    end

    oldMultiItemConfig = {
            'data' => [
                {
                'object_id' => 'foo',
                'title'     => 'bar'
                },
                {
                'object_id' => 'shoe',
                'title'     => 'sock'
                },
              ]
            }

    specify 'should call update if in create mode and item does not exist' do
      Nexus::Rest.stub(:get_all).and_return(oldMultiItemConfig)
      newHash = {
        'object_id' => 'foofoo',
        'title'     => 'barbar'
      }
      Nexus::Rest.should_receive(:create).with('/here', anything())
      Nexus::Rest.should_not_receive(:update)
      flush(newHash, :create, 'object_id')
    end
    specify 'should not call update if in create mode and item does exist' do
      Nexus::Rest.stub(:get_all).and_return(oldMultiItemConfig)
      newHash = {
        'object_id' => 'foo',
        'title'     => 'barbar'
      }
      Nexus::Rest.should_not_receive(:create)
      Nexus::Rest.should_not_receive(:update)
      flush(newHash, :create, 'object_id')
    end
    specify 'should raise a human readable error message if the operation failed' do
      Nexus::Rest.should_receive(:get_all).and_raise('Operation failed')
      expect { flush({}, :update, 'id') }.to raise_error(Puppet::Error, /Error while updating nexus_generic_settings/)
    end
  end
end
