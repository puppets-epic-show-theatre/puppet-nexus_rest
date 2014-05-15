require 'spec_helper'

provider_class = Puppet::Type.type(:nexus_global_settings).provider(:ruby)

describe provider_class do
  before(:each) do
    Nexus::Config.stub(:resolve).and_return('http://example.com/foobar')
  end

  describe 'instances' do
    let :instances do
      Nexus::Rest.should_receive(:get_all).with('/service/local/global_settings/current').and_return({'data' => {}})
      Nexus::Rest.should_receive(:get_all).with('/service/local/global_settings/default').and_return({'data' => {}})
      provider_class.instances
    end

    it { instances.should have(2).items }
  end
end
