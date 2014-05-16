require 'json'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'config.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'exception.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'rest.rb'))

Puppet::Type.type(:nexus_global_settings).provide(:ruby) do
  desc "Nexus settings management based on Ruby."

  def self.instances
    begin
      [
        map_data_to_resource('current', Nexus::Rest.get_all('/service/local/global_settings/current')),
        map_data_to_resource('default', Nexus::Rest.get_all('/service/local/global_settings/default'))
      ]
    rescue => e
      raise Puppet::Error, "Error while retrieving settings: #{e}"
    end
  end

  def self.prefetch(resources)
    settings = instances
    settings.keys.each do |name|
      if provider = settings.find { |setting| setting.name == name }
        resources[name].provider = provider
      end
    end
  end

  def self.map_data_to_resource(name, settings)
    new(
      :name => name,
    )
  end
end
