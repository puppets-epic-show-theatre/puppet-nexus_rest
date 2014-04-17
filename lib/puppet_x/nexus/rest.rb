require 'json'
require 'yaml'
require 'rest_client'

module Nexus
  class Rest
    def self.request
      Nexus::Config.configure { |base_url, options|
        nexus = RestClient::Resource.new(
          base_url,
          :user         => options[:username],
          :password     => options[:password],
          :timeout      => options[:timeout],
          :open_timeout => options[:open_timeout]
        )
        yield nexus
      }
    end

    def self.get_all(resource_name)
      request { |nexus|
        begin
          response = nexus[resource_name].get(:accept => :json)
        rescue => e
          raise "Could not request #{resource_name} from #{nexus.url}: #{e}"
        end

        begin
          JSON.parse(response)
        rescue => e
          raise "Could not parse the JSON response from Nexus (url: #{nexus.url}, resource: #{resource_name}): #{e} (response: #{response})"
        end
      }
    end

    def self.create(resource_name, data)
      request { |nexus|
        begin
          nexus[resource_name].post JSON.generate(data), :accept => :json, :content_type => :json
        rescue Exception => e
          error_message = format_error_message(e.http_body)
          raise "Could not create #{resource_name} at #{nexus.url}: #{e} - #{error_message}"
        end
      }
    end

    def self.update(resource_name, data)
      request { |nexus|
        begin
          nexus[resource_name].put JSON.generate(data), :accept => :json, :content_type => :json
        rescue Exception => e
          Puppet::debug("Update of #{resource_name} at #{nexus.url} failed: #{e.http_body}")
          error_message = format_error_message(e.http_body)
          raise "Could not update #{resource_name} at #{nexus.url}: #{e} - #{error_message}"
        end
      }
    end

    def self.destroy(resource_name)
      request { |nexus|
        begin
          nexus[resource_name].delete :accept => :json
        rescue RestClient::ResourceNotFound
          # resource already deleted, nothing to do
        rescue Exception => e
          Puppet::debug("Delete of #{resource_name} at #{nexus.url} failed: #{e.http_body}")
          error_message = format_error_message(e.http_body)
          raise "Could not delete #{resource_name} at #{nexus.url}: #{e} - #{error_message}"
        end
      }
    end

    def self.format_error_message(data)
      if data.class == {}.class && !data.empty?
        # The data normally looks like
        # {
        #    "errors":
        #    [
        #        {
        #            "id": "*",
        #            "msg": "... <long error message> ..."
        #        }
        #    ]
        # }
        data[:errors].collect {|entry| entry[:msg] }.join(' ')
      else
        '<unknown>'
      end
    end
  end
end
