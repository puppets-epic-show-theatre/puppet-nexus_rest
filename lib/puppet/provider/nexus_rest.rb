require 'net/http'
require 'json'
require 'yaml'
require 'rest_client'

module Nexus
  class Config
    CONFIG_FILE_NAME = '/etc/puppet/nexus_rest.conf'
    CONFIG_BASE_URL = 'base_url'
    CONFIG_ADMIN_USERNAME = 'admin_username'
    CONFIG_ADMIN_PASSWORD = 'admin_password'

    def self.base_url
      return config[CONFIG_BASE_URL].chomp('/')
    end

    def self.admin_username
      return config[CONFIG_ADMIN_USERNAME]
    end

    def self.admin_password
      return config[CONFIG_ADMIN_PASSWORD]
    end

    def self.config
      @config  ||= read_config
    end

    def self.read_config
      # todo: add autorequire soft dependency
      begin
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

      config
    end
  end

  class Rest
    def self.generate_url(resource_name)
      base_url = Nexus::Config.base_url
      URI("#{base_url}#{resource_name}")
    end

    def self.get_all(resource_name)
      uri = generate_url(resource_name)
      Net::HTTP.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Get.new uri.request_uri, {'Accept' => 'application/json'}

        response = http.request request
        case response
        when Net::HTTPSuccess then
          begin
            return responseJson = JSON.parse(response.body)
          rescue
            raise Puppet::Error,"Could not parse the JSON response from Nexus: " + response.body
          end
        else
          # todo notice
          return []
        end
      end
    end

    def self.create(resource_name, data)
      base_url = Nexus::Config.base_url
      admin_username = Nexus::Config.admin_username
      admin_password = Nexus::Config.admin_password
      begin
        nexus = RestClient::Resource.new(base_url, :user => admin_username, :password => admin_password, :headers => {:accept => :json})
        nexus[resource_name].post JSON.generate(data), :content_type => :json
      rescue Exception => e
        raise "Failed to submit POST to #{base_url}#{resource_name}: #{e}"
      end
    end

    def self.update(resource_name, data)
      base_url = Nexus::Config.base_url
      admin_username = Nexus::Config.admin_username
      admin_password = Nexus::Config.admin_password
      begin
        nexus = RestClient::Resource.new(base_url, :user => admin_username, :password => admin_password, :headers => {:accept => :json})
        nexus[resource_name].put JSON.generate(data), :content_type => :json
      rescue Exception => e
        raise "Failed to submit PUT to #{base_url}#{resource_name}: #{e}"
      end
    end

    def self.destroy(resource_name)
      base_url = Nexus::Config.base_url
      admin_username = Nexus::Config.admin_username
      admin_password = Nexus::Config.admin_password
      begin
        nexus = RestClient::Resource.new(base_url, :user => admin_username, :password => admin_password, :headers => {:accept => :json})
        nexus[resource_name].delete
      rescue RestClient::ResourceNotFound
        # resource already deleted, nothing to do
      rescue Exception => e
        raise "Failed to submit DELETE to #{base_url}#{resource_name}: #{e}"
      end
    end
  end
end
