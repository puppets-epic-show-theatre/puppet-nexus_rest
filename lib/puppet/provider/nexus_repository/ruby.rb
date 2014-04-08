require 'net/http'
require 'json'

Puppet::Type.type(:nexus_repository).provide(:ruby) do
    desc "Uses Ruby's rest library"

    def self.instances
      uri = URI("http://example.com/service/local/repositories")
      Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
        request = Net::HTTP::Get.new uri.request_uri

        response = http.request request
        case response
        when Net::HTTPSuccess then
          begin
            responseJson = JSON.parse(response.body)
          rescue
            raise Puppet::Error,"Could not parse the JSON response from Nexus: " + response.body
          end

          return responseJson['data'].collect do |repository|
            name = repository['id']
            new(:name => name)
          end
        else
          # todo notice
          return []
        end
      end
    end

    def create
      uri = URI("http://example.com/service/local/repositories")
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

    def update
      uri = URI("http://example.com/service/local/repositories/example")
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

    def destroy
      uri = URI("http://example.com/service/local/repositories/#{resource[:name]}")
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

    def exists?
      uri = URI("http://example.com/service/local/repositories/#{resource[:name]}")
      Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
        request = Net::HTTP::Get.new uri.request_uri

        response = http.request request
        case response
        when Net::HTTPSuccess then
          return true
        when Net::HTTPNotFound then
          return false
        else
          raise Puppet::Error, "Failed to check existence of puppet resource: " + response.code + " - " + response.msg
        end
      end
    end
end