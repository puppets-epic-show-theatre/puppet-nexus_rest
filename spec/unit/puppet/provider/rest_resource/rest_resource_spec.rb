require 'spec_helper'

provider_class = Puppet::Type.type(:rest_resource).provider(:rest)

describe provider_class do

    let :resource do
      Puppet::Type.type(:rest_resource).new(
            :name     => 'example',
            :baseurl  => 'http://example.com',
            :resource => "/api/users",
            :timeout  => 10,
      )
    end
    let :provider do
      provider_class.new(resource)
    end
    
    it "should create a simple rest call" do
      provider.exists?.should be_false
    end
end

