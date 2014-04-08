require 'net/http'
require 'json'

module Nexus
  module Resources
    def self.get(resource_name)
      uri = URI("http://example.com#{resource_name}")
      Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
        request = Net::HTTP::Get.new uri.request_uri

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
  end

  module Resource
    def self.create(resource_name)
      uri = URI("http://example.com#{resource_name}")
      Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
        request = Net::HTTP::Post.new uri.request_uri

        response = http.request request
        case response
        when Net::HTTPSuccess then
        else
          raise Puppet::Error, "Failed to create nexus_repository #{resource[:name]}: " + response.code + " - " + response.msg
        end
      end
    end

    def self.update(resource_name)
      uri = URI("http://example.com#{resource_name}")
      Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
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
      uri = URI("http://example.com#{resource_name}")
      Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
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
