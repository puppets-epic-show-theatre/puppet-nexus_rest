source 'http://rubygems.org'

if puppetversion = ENV['PUPPET_VERSION']
  gem 'puppet', puppetversion
else
  gem 'puppet', '~> 3.4.0'
end

gem 'json', '~> 1.8.1'
gem 'rest-client', '~> 1.6.7'
gem 'mime-types', '< 2.0'

group :test do
  gem 'rake', '~> 10.2.2'
  gem 'rspec-puppet', '~> 1.0.1'
  gem 'rspec_junit_formatter', '~> 0.1.6'
  gem 'puppetlabs_spec_helper', '~> 0.4.1'
  gem 'webmock', '~> 1.17.4'
  gem 'excon', '~> 0.27.5'
end
