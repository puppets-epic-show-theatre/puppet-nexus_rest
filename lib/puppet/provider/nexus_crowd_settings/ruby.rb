  require 'json'
  require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'config.rb'))
  require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'exception.rb'))
  require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'rest.rb'))

  Puppet::Type.type(:nexus_crowd_settings).provide(:ruby) do
    desc "Manages the crowd settings."

    confine :feature => :restclient

    def self.nexus_resource
      '/service/siesta/crowd/config'
    end

    def initialize(value={})
      super(value)
    end

    def self.instances
      crowd_settings = get_current_crowd_settings
      hash = map_config_to_resource_hash(crowd_settings)
      hash[:name] = 'current'
      [new(hash)]
    end

    def self.map_config_to_resource_hash(crowd_settings)
      {
        :application_name     => crowd_settings["applicationName"],
        :application_password => crowd_settings["applicationPassword"] ? :present : :absent,
        :crowd_server_url     => crowd_settings["crowdServerUrl"],
        :http_timeout         => crowd_settings["httpTimeout"],
      }
    end

    def map_resource_hash_to_config
      config = { "data" => {} }
      config["data"]["applicationName"] = resource[:application_name] unless resource[:application_name].nil?
      config["data"]["applicationPassword"] = resource[:application_password_value] unless resource[:application_password_value].nil?
      config["data"]["crowdServerUrl"] = resource[:crowd_server_url] unless resource[:crowd_server_url].nil?
      config["data"]["httpTimeout"] = resource[:http_timeout] unless resource[:http_timeout].nil?

      config
    end

    def self.prefetch(resources)
      settings = instances
      resources.keys.each do |name|
        if provider = settings.find { |setting| setting.name == name }
          resources[name].provider = provider
        end
      end
    end

    def self.get_current_crowd_settings
      begin
        data = Nexus::Rest.get_all(self.nexus_resource)
        data['data']
      rescue => e
        raise Puppet::Error, "Error while retrieving crowd setting 'current': #{e}"
      end
    end

    def flush
      update_crowd_settings
      @property_hash = resource.to_hash
    end

    def update_crowd_settings
      begin
        Puppet::debug(map_resource_hash_to_config)
        Nexus::Rest.update(self.class.nexus_resource, map_resource_hash_to_config)
      rescue Exception => e
        raise Puppet::Error, "Error while updating crowd settings '#{resource[:name]}': #{e}"
      end
    end

    mk_resource_methods
  end
