source 'http://rubygems.org'

puppetversion = ENV['PUPPET_VERSION'] || '~> 4.8.2'

gem 'puppet', puppetversion
gem 'rest-client', '>= 1.8.0'

group :development do
  gem 'guard-rspec', '~> 4.2.9', :require => false
end

group :test do
  gem 'rake', '~> 12'
  gem 'rspec-puppet', '~> 2.6'
  gem 'rspec_junit_formatter', '~> 0.3'
  gem 'puppetlabs_spec_helper', '~> 2.6'
  gem 'webmock', '~> 3.3'
  gem 'excon', '>= 0.71.0'
end
