require 'json'

require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'config.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'exception.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'rest.rb'))

Puppet::Type.type(:nexus_generic_settings).provide(:ruby) do
  desc "Ruby-based management of the Nexus generic settings."

  confine :feature => :restclient

  def initialize(value={})
    super(value)
    @update_required = false
  end

  def self.get_current_config(resource)
    begin
      url = resource[:api_url_fragment]
      data = Nexus::Rest.get_all(resource[:api_url_fragment])
      data['data']
    rescue => e
      raise Puppet::Error, "Error while retrieving generic configuration '#{resource[:name]}': #{e}"
    end
  end


  def update_config(config)
    begin
      data = {
        :data => config
      }
      if (resource[:action] == :create)
        Nexus::Rest.create(resource[:api_url_fragment], data)
      else
        Nexus::Rest.update(resource[:api_url_fragment], data)
      end
    rescue Exception => e
      raise Puppet::Error, "Error while updating generic configuration '#{resource[:name]}': #{e}"
    end
  end

  def self.map_config_to_resource_hash(config)
    {
      :settings_hash => config
    }
  end

  def fix_numbers_in_hash(hash)
    # Puppet resource hashes always seem to come through
    # with String values
    # Nexus REST API does not cope with Integer fields
    # quoted in JSON, so need to convert these to Integers where possible
    hash.each do |key, item|
      if (item.instance_of? Hash)
        fix_numbers_in_hash(item)
      elsif ((item.instance_of? String) && (item.to_i.to_s == item))
        hash[key] = item.to_i
      end
    end
  end

  def map_resource_to_config
    newHash = resource[:settings_hash]
    fix_numbers_in_hash(newHash)
    if (resource[:merge])
      currentConfig = self.class.get_current_config(resource)
      merged = currentConfig.merge(newHash)
    else
      newHash
    end
  end

  def flush
    begin
      update_required = false
      oldConfig = self.class.get_current_config(resource)
      newConfig = map_resource_to_config

      if (resource[:action] == :update)
        if (newConfig == oldConfig)
          Puppet::debug("Not updating generic config #{resource[:name]} - unchanged")
        else
          update_required = true
        end
      elsif (resource[:action] == :create)
        if (newConfig.key?(resource[:id_field]))
          id = newConfig[resource[:id_field]]
          update_required = oldConfig.none? { |item| item[resource[:id_field]] == id }
          if (!update_required)
            Puppet::debug("Not creating generic config #{resource[:name]} - ID #{id} already exists")
          end
        else
          update_required = true
        end
      end
      if update_required
        update_config(newConfig)
        @property_hash = resource.to_hash
      end
    rescue Exception => e
      raise Puppet::Error, "Error while updating nexus_generic_settings #{resource[:name]}: #{e}"
    end
  end

  def self.instances(resource)
    config = self.get_current_config(resource)
    hash = self.map_config_to_resource_hash(config)
    hash[:name] = 'current'
    [new(hash)]
  end

  def self.prefetch(resources)
    resources.each do |name, resource|
      settings = instances(resource)
      has = resource[:settings_hash]
      if provider = settings.find { |setting| setting.name == name }
        resources[name].provider = provider
      end
    end
  end

  mk_resource_methods

end
