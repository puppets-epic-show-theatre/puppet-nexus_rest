require 'json'
require 'yaml'
require 'rest_client'

module Nexus
  class Rest
    def self.request
      Nexus::Config.configure { |base_url, username, password, timeout|
        nexus = RestClient::Resource.new(base_url, :user => username, :password => password, :timeout => timeout)
        yield nexus
      }
    end

    def self.get_all(resource_name)
      request { |nexus|
        begin
          response = nexus[resource_name].get(:accept => :json)
        rescue => e
          raise "Failed to submit GET to #{resource_name}"
        end

        begin
          JSON.parse(response)
        rescue => e
          raise "Could not parse the JSON response from Nexus (url: #{nexus.url}, resource: #{resource_name}): #{response}"
        end
      }
    end

    def self.create(resource_name, data)
      request { |nexus|
        begin
          nexus[resource_name].post JSON.generate(data), :content_type => :json
        rescue Exception => e
          raise "Failed to submit POST to #{resource_name}: #{e}"
        end
      }
    end

    def self.update(resource_name, data)
      request { |nexus|
        begin
          nexus[resource_name].put JSON.generate(data), :content_type => :json
        rescue Exception => e
          raise "Failed to submit PUT to #{resource_name}: #{e}"
        end
      }
    end

    def self.destroy(resource_name)
      request { |nexus|
        begin
          nexus[resource_name].delete
        rescue RestClient::ResourceNotFound
          # resource already deleted, nothing to do
        rescue Exception => e
          raise "Failed to submit DELETE to #{resource_name}: #{e}"
        end
      }
    end
  end
end
