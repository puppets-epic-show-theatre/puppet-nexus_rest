require 'json'
require 'puppet'
require 'rest_client'
require 'yaml'

module Nexus
  class Config
    CONFIG_NEXUS_BASE_URL = :nexus_base_url
    CONFIG_ADMIN_USERNAME = :admin_username
    CONFIG_ADMIN_PASSWORD = :admin_password
    CONFIG_KILL_SWITCH_DISABLED = :kill_switch_disabled
    CONFIG_CONNECTION_TIMEOUT = :connection_timeout
    CONFIG_CONNECTION_OPEN_TIMEOUT = :connection_open_timeout

    def self.configure
      @config ||= read_config
      yield @config[CONFIG_NEXUS_BASE_URL], @config
    end

    # Returns: the full path to the file where this class sources its information from.
    #
    # Notice: any provider should have a soft dependency on this file to make sure it is created before usage.
    #
    def self.file_path
      @config_file_path ||= File.expand_path(File.join(Puppet.settings[:confdir], '/nexus_rest.conf'))
    end

    def self.kill_switch_enabled
      configure { |nexus_base_url, options| options[CONFIG_KILL_SWITCH_DISABLED] == false}
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
        # each loop used to convert hash keys from String to Symbol; each doesn't return the modified hash ... ugly, I know
        config = Hash.new
        YAML.load_file(file_path).each{ |key, value| config[key.intern] = value}
      rescue => e
        raise Puppet::ParseError, "Could not parse YAML configuration file '#{file_path}': #{e}"
      end

      if config[CONFIG_NEXUS_BASE_URL].nil?
        raise Puppet::ParseError, "Config file #{file_path} must contain a value for key '#{CONFIG_NEXUS_BASE_URL}'."
      end
      # TODO: add warning about insecure connection if protocol is http and host not localhost (credentials sent in plain text)
      if config[CONFIG_ADMIN_USERNAME].nil?
        raise Puppet::ParseError, "Config file #{file_path} must contain a value for key '#{CONFIG_ADMIN_USERNAME}'."
      end
      if config[CONFIG_ADMIN_PASSWORD].nil?
        raise Puppet::ParseError, "Config file #{file_path} must contain a value for key '#{CONFIG_ADMIN_PASSWORD}'."
      end
      if config[CONFIG_KILL_SWITCH_DISABLED].nil?
        raise Puppet::ParseError, "Config file #{file_path} must contain a value for key '#{CONFIG_KILL_SWITCH_DISABLED}'."
      end
      config[CONFIG_CONNECTION_TIMEOUT] = 10 if config[CONFIG_CONNECTION_TIMEOUT].nil?
      config[CONFIG_CONNECTION_OPEN_TIMEOUT] = 10 if config[CONFIG_CONNECTION_OPEN_TIMEOUT].nil?

      {
        CONFIG_NEXUS_BASE_URL          => config[CONFIG_NEXUS_BASE_URL].chomp('/'),
        CONFIG_ADMIN_USERNAME          => config[CONFIG_ADMIN_USERNAME],
        CONFIG_ADMIN_PASSWORD          => config[CONFIG_ADMIN_PASSWORD],
        CONFIG_KILL_SWITCH_DISABLED    => config[CONFIG_KILL_SWITCH_DISABLED],
        CONFIG_CONNECTION_TIMEOUT      => Integer(config[CONFIG_CONNECTION_TIMEOUT]),
        CONFIG_CONNECTION_OPEN_TIMEOUT => Integer(config[CONFIG_CONNECTION_OPEN_TIMEOUT]),
      }
    end
  end
end
