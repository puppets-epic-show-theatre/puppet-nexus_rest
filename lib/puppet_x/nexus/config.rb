require 'json'
require 'puppet'
require 'rest_client'
require 'yaml'

module Nexus
  class Config
    CONFIG_BASE_URL = 'nexus_base_url'
    CONFIG_USERNAME = 'admin_username'
    CONFIG_PASSWORD = 'admin_password'
    CONFIG_TIMEOUT = 'connection_timeout'
    CONFIG_OPEN_TIMEOUT = 'connection_open_timeout'

    def self.configure
      @config ||= read_config
      yield @config[:nexus_base_url], {
        :admin_username          => @config[:admin_username],
        :admin_password          => @config[:admin_password],
        :connection_timeout      => @config[:connection_timeout],
        :connection_open_timeout => @config[:connection_open_timeout]
      }
    end

    # Returns: the full path to the file where this class sources its information from.
    #
    # Notice: any provider should have a soft dependency on this file to make sure it is created before usage.
    #
    def self.file_path
      @config_file_path ||= File.expand_path(File.join(Puppet.settings[:confdir], '/nexus_rest.conf'))
    end

    def self.reset
      @config = nil
    end

    def self.resolve(url)
      unless url.start_with?('http')
        configure { |nexus_base_url, options|
          URI.join(nexus_base_url, url).to_s
        }
      else
        url
      end
    end

    def self.read_config
      begin
        Puppet::debug("Parsing configuration file #{file_path}")
        config = YAML.load_file(file_path)
      rescue => e
        raise Puppet::ParseError, "Could not parse YAML configuration file '#{file_path}': #{e}"
      end

      if config[CONFIG_BASE_URL].nil?
        raise Puppet::ParseError, "Config file #{file_path} must contain a value for key '#{CONFIG_BASE_URL}'."
      end
      # TODO: add warning about insecure connection if protocol is http and host not localhost (credentials sent in plain text)
      if config[CONFIG_USERNAME].nil?
        raise Puppet::ParseError, "Config file #{file_path} must contain a value for key '#{CONFIG_USERNAME}'."
      end
      if config[CONFIG_PASSWORD].nil?
        raise Puppet::ParseError, "Config file #{file_path} must contain a value for key '#{CONFIG_PASSWORD}'."
      end
      config[CONFIG_TIMEOUT] = 10 if config[CONFIG_TIMEOUT].nil?
      config[CONFIG_OPEN_TIMEOUT] = 10 if config[CONFIG_OPEN_TIMEOUT].nil?

      {
        :nexus_base_url          => config[CONFIG_BASE_URL].chomp('/'),
        :admin_username          => config[CONFIG_USERNAME],
        :admin_password          => config[CONFIG_PASSWORD],
        :connection_timeout      => Integer(config[CONFIG_TIMEOUT]),
        :connection_open_timeout => Integer(config[CONFIG_OPEN_TIMEOUT]),
      }
    end
  end
end
