require 'spec_helper'
include WebMock::API

describe Nexus::Resources do
  describe 'instances' do
    let :instances do
      stub_request(:any, 'example.com/service/local/repositories').to_return(:body => '{ "data": [{"id": "repository-1"}, {"id": "repository-2"}] }')
      Nexus::Resources.get('/service/local/repositories')
    end

    it { instances['data'].should have(2).items }
  end
end
