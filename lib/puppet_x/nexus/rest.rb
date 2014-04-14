require 'json'
require 'yaml'
require 'rest_client'

module Nexus
  class Rest
    def self.request
      Nexus::Config.configure { |base_url, admin_username, admin_password|
        nexus = RestClient::Resource.new(base_url, :user => admin_username, :password => admin_password)
        yield nexus
      }
    end

    def self.get_all(resource_name)
      request { |nexus|
        begin
          response = nexus[resource_name].get(:accept => :json)
        rescue => e
          []
        end

        begin
          JSON.parse(response)
        rescue => e
          raise Puppet::Error,"Could not parse the JSON response from Nexus: #{response}"
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
