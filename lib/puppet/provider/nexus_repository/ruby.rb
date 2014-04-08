require 'net/http'

Puppet::Type.type(:nexus_repository).provide(:ruby) do
    desc "Uses Ruby's rest library"

    def create
        # todo
    end

    def destroy
        # todo
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
          return false
        end
      end
    end
end