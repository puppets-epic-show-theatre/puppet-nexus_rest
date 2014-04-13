require 'json'
require 'yaml'
require 'rest_client'

module Nexus
  class Config
    CONFIG_FILE_NAME = '/etc/puppet/nexus_rest.conf'
    CONFIG_BASE_URL = 'base_url'
    CONFIG_ADMIN_USERNAME = 'admin_username'
    CONFIG_ADMIN_PASSWORD = 'admin_password'

    def self.configure
      @config ||= read_config
      yield @config[:base_url], @config[:admin_username], @config[:admin_password]
    end

    def self.reset
      @config = nil
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
      if config[CONFIG_ADMIN_USERNAME].nil?
        raise Puppet::ParseError, "Config file #{CONFIG_FILE_NAME} must contain a value for key '#{CONFIG_ADMIN_USERNAME}'."
      end
      if config[CONFIG_ADMIN_PASSWORD].nil?
        raise Puppet::ParseError, "Config file #{CONFIG_FILE_NAME} must contain a value for key '#{CONFIG_ADMIN_PASSWORD}'."
      end

      {
        :base_url       => config[CONFIG_BASE_URL].chomp('/'),
        :admin_username => config[CONFIG_ADMIN_USERNAME],
        :admin_password => config[CONFIG_ADMIN_PASSWORD],
      }
    end
  end
end
