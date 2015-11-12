require 'json'
require 'yaml'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'puppet_x', 'nexus', 'service.rb'))

module Nexus
  class Rest
    def self.request
      Nexus::Config.configure { |nexus_base_url, options|
        nexus = RestClient::Resource.new(
          nexus_base_url,
          :user         => options[:admin_username],
          :password     => options[:admin_password],
          :timeout      => options[:connection_timeout],
          :open_timeout => options[:connection_open_timeout]
        )
        yield nexus
      }
    end

    # Request the given resource from the configured Nexus instance.
    #
    # Returns the JSON response as received, does not apply any post-processing.
    #
    def self.get_all(resource_name)
      service.ensure_running
      request { |nexus|
        begin
          response = nexus[resource_name].get(:accept => :json)
        rescue => e
          Nexus::ExceptionHandler.process(e) { |msg|
            raise "Could not request #{resource_name} from #{nexus.url}: #{msg}"
          }
        end

        begin
          JSON.parse(response)
        rescue => e
          raise "Could not parse the JSON response from Nexus (url: #{nexus.url}, resource: #{resource_name}): #{e} (response: #{response})"
        end
      }
    end

    def self.service
      @service ||= init_service
    end

    def self.init_service
      Nexus::Config.configure { |nexus_base_url, options|
        client = Nexus::Service::HealthCheckClient.new(options)
        service = Nexus::Service.new(client, options)
        Nexus::CachingService.new(service)
      }
    end

    # Request a resource that returns a list of resources and do an additional request per resource.
    #
    # Due to unknown reasons, some REST resources do not expose all attributes in the list view. Hence, an additional
    # REST request is made for each returned resource.
    #
    # Returns a hash similar like the original resource; the hash will always contain `data => [ ... ]` in the result,
    # even through it was originally not returned by the specified resource.
    #
    def self.get_all_plus_n(resource_name)
      resource_list = get_all(resource_name)
      if !resource_list
        {'data' => []}
      elsif
        resource_details = resource_list.fetch('data', []).collect { |resource| get_all("#{resource_name}/#{resource['id']}") }

        # At this point, resource_details is a list of data hashes similar like
        #
        # [{ 'data': { 'id': ..., 'name': ... } }, { 'data': ...}]
        #
        # It has to be 'unwrapped' to match the expect data structure:
        #
        # {
        #    'data': [{
        #               'id': ...
        #               'name': ...
        #             }, {
        #                ...
        #             }]
        # }
        {'data' => resource_details.collect { |resource| resource['data'] } }
      end
    end

    def self.create(resource_name, data)
      service.ensure_running
      request { |nexus|
        begin
          nexus[resource_name].post JSON.generate(data), :accept => :json, :content_type => :json
        rescue => e
          Nexus::ExceptionHandler.process(e) { |msg|
            raise "Could not create #{resource_name} at #{nexus.url}: #{msg}"
          }
        end
      }
    end

    def self.update(resource_name, data)
      service.ensure_running
      request { |nexus|
        begin
          nexus[resource_name].put JSON.generate(data), :accept => :json, :content_type => :json
        rescue => e
          Nexus::ExceptionHandler.process(e) { |msg|
            raise "Could not update #{resource_name} at #{nexus.url}: #{msg}"
          }
        end
      }
    end

    def self.destroy(resource_name)
      service.ensure_running
      request { |nexus|
        begin
          nexus[resource_name].delete :accept => :json
        rescue RestClient::ResourceNotFound
          # resource already deleted, nothing to do
        rescue => e
          Nexus::ExceptionHandler.process(e) { |msg|
            raise "Could not delete #{resource_name} at #{nexus.url}: #{msg}"
          }
        end
      }
    end
  end
end
