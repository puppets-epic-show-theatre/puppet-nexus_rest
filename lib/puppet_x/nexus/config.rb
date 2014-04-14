require 'json'
require 'yaml'
require 'rest_client'

module Nexus
  class Config
    CONFIG_FILE_NAME = '/etc/puppet/nexus_rest.conf'
    CONFIG_BASE_URL = 'base_url'
    CONFIG_USERNAME = 'username'
    CONFIG_PASSWORD = 'password'
    CONFIG_TIMEOUT = 'timeout'

    def self.configure
      @config ||= read_config
      yield @config[:base_url], @config[:username], @config[:password], @config[:timeout]
    end

    def self.reset
      @config = nil
    end

    def self.resolve(url)
      unless url.start_with?('http')
        configure { |base_url, username, password, timeout|
          URI.join(base_url, url).to_s
        }
      else
        url
      end
    end

    def self.read_config
      # todo: add autorequire soft dependency
      begin
        Puppet::notice("Parsing configuration file #{CONFIG_FILE_NAME}")
        config = YAML.load_file(CONFIG_FILE_NAME)
      rescue
        raise Puppet::ParseError, "Could not parse YAML configuration file " + CONFIG_FILE_NAME + " " + $!.inspect
      end

      if config[CONFIG_BASE_URL].nil?
        raise Puppet::ParseError, "Config file #{CONFIG_FILE_NAME} must contain a value for key '#{CONFIG_BASE_URL}'."
      end
      if config[CONFIG_USERNAME].nil?
        raise Puppet::ParseError, "Config file #{CONFIG_FILE_NAME} must contain a value for key '#{CONFIG_USERNAME}'."
      end
      if config[CONFIG_PASSWORD].nil?
        raise Puppet::ParseError, "Config file #{CONFIG_FILE_NAME} must contain a value for key '#{CONFIG_PASSWORD}'."
      end
      config[CONFIG_TIMEOUT] = 10 if config[CONFIG_TIMEOUT].nil?

      {
        :base_url => config[CONFIG_BASE_URL].chomp('/'),
        :username => config[CONFIG_USERNAME],
        :password => config[CONFIG_PASSWORD],
        :timeout  => Integer(config[CONFIG_TIMEOUT]),
      }
    end
  end
end
