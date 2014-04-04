require 'spec_helper'

provider_class = Puppet::Type.type(:nexus_repository).provider(:ruby)

describe provider_class do

    let :resource do
      Puppet::Type.type(:nexus_repository).new(
            :name     => 'example',
            :baseurl  => 'http://example.com',
            :resource => "/api/users",
            :timeout  => 10
      )
    end
    let :provider do
      provider_class.new(resource)
    end
    
    it "should create a simple rest call" do
      provider.exists?.should be_false
    end
end

