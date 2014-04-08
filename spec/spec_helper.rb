require 'rubygems'
require 'rspec-puppet'
require 'puppetlabs_spec_helper/module_spec_helper'
require 'webmock/rspec'

# see https://github.com/bblimke/webmock#connecting-on-nethttpstart
WebMock.allow_net_connect!(:net_http_connect_on_start => true)
