require 'net/http'
require 'json'
require 'yaml'

module Nexus
  class Config
    CONFIG_FILE_NAME = '/etc/puppet/nexus_rest.conf'
    CONFIG_BASE_URL = 'base_url'
    CONFIG_ADMIN_USERNAME = 'admin_username'
    CONFIG_ADMIN_PASSWORD = 'admin_password'

    def self.base_url
      return config[CONFIG_BASE_URL].chomp('/')
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

    def self.create(resource_name)
      uri = generate_url(resource_name)
      Net::HTTP.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Post.new uri.request_uri

        response = http.request request
        case response
        when Net::HTTPSuccess then
        else
          raise "Failed to submit POST to #{uri}: #{response.msg} (response code #{response.code})"
        end
      end
    end

    def self.update(resource_name)
      uri = generate_url(resource_name)
      Net::HTTP.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Put.new uri.request_uri

        response = http.request request
        case response
        when Net::HTTPSuccess then
        else
          raise Puppet::Error, "Failed to create nexus_repository #{resource[:name]}: " + response.code + " - " + response.msg
        end
      end
    end

    def self.destroy(resource_name)
      uri = generate_url(resource_name)
      Net::HTTP.start(uri.host, uri.port) do |http|
        request = Net::HTTP::Delete.new uri.request_uri

        response = http.request request
        case response
        when Net::HTTPSuccess then
        when Net::HTTPNotFound then
        else
          raise Puppet::Error, "Failed to delete nexus_repository #{resource[:name]}: " + response.code + " - " + response.msg
        end
      end
    end
  end
end
