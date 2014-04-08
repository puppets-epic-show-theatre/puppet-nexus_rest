require 'net/http'
require 'json'
require File.join(File.dirname(__FILE__), '..', 'nexus')

Puppet::Type.type(:nexus_repository).provide(:ruby) do
    desc "Uses Ruby's rest library"

    def self.instances
      repositories = Nexus::Resources.get('/service/local/repositories')
      return repositories['data'].collect do |repository|
        name = repository['id']
        new(:name => name)
      end
    end

    def create
      Nexus::Resource.create('/service/local/repositories')
    end

    def update
      Nexus::Resource.update("/service/local/repositories/#{resource[:name]}")
    end

    def destroy
      Nexus::Resource.destroy("/service/local/repositories/#{resource[:name]}")
    end

    def exists?
      # todo: will be replaced with property lookup soon
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