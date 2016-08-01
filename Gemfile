source 'http://rubygems.org'

puppetversion = ENV['PUPPET_VERSION'] || '~> 3.7.3'

gem 'puppet', puppetversion
gem 'json', '~> 1.8.1'
gem 'json_pure', '~> 1.8.2'   # Ruby 1.8.7 compatible version
gem 'rest-client', '~> 1.6.7' # Ruby 1.8.7 compatible version
gem 'mime-types', '< 2.0'
gem 'addressable', '~> 2.2.7' # Ruby 1.8.7 compatible version

group :development do
  gem 'guard-rspec', '~> 4.2.9', :require => false
end

group :test do
  gem 'rake', '~> 10.2.2'
  gem 'rspec-puppet', '~> 1.0.1'
  gem 'rspec_junit_formatter', '~> 0.1.6'
  gem 'puppetlabs_spec_helper', '~> 0.4.1'
  gem 'webmock', '~> 1.17.4'
  gem 'excon', '~> 0.27.5' # required by webmock
end
