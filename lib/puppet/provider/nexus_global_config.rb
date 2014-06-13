require 'json'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'puppet_x', 'nexus', 'config.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'puppet_x', 'nexus', 'exception.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'puppet_x', 'nexus', 'rest.rb'))

class Puppet::Provider::NexusGlobalConfig < Puppet::Provider
  desc "Manage the global configuration."

  @@global_config_rest_resource = '/service/local/global_settings'

  def initialize(value={})
    super(value)
    @update_required = false
  end

  # Hook to return all instances of a resource type that its provider finds on the current system. Mainly used when
  # invoking `puppet resource`.
  #
  # Relies on the `map_config_to_resource_hash` method being implemented by any provider extending this class.
  #
  def self.instances
    global_config = get_current_global_config
    hash = map_config_to_resource_hash(global_config)
    hash[:name] = 'current'
    [new(hash)]
  end

  # Map the current global configuration to a hash which is used to create a new resource instance.
  #
  # This method is expected to be implemented by inheriting classes.
  #
  # global_config: A map of data as received from the config REST resource except that leading data has been stripped.
  # {
  #    ...
  #    'securityRealms': ...
  #    'globalConnectionSettings': ...
  #    'systemNotificationSettings': ...
  #    'smtpSettings': ...
  #    ...
  # }
  #
  # returns: A map of data representing the Puppet resource state.
  # {
  #    :puppet_attribute_1 => ...,
  #    :puppet_attribute_2 => ...,
  #    :puppet_attribute_3 => ...,
  # }
  #
  def self.map_config_to_resource_hash(global_config)
    notice("Method 'map_config_to_resource_hash' should be implemented")
  end

  # Hook that is always invoked before any resources of that type are applied. Used when invoking `puppet agent` or
  # `puppet apply`.
  #
  def self.prefetch(resources)
    settings = instances
    resources.keys.each do |name|
      if provider = settings.find { |setting| setting.name == name }
        resources[name].provider = provider
      end
    end
  end

  # Returns the current configuration
  #
  # Notes:
  # * The REST API support multiple configurations, but there is only `current` and `default`
  # * The `default` configuration looks quite different and I don't see much value in managing it anyway - hence it is
  #   excluded
  #
  # returns: The data as expected by the remote REST resource but without the data 'envelop'.
  # {
  #    'attribute1': ...
  #    'attribute2': ...
  # }
  #
  def self.get_current_global_config
    begin
      data = Nexus::Rest.get_all("#{@@global_config_rest_resource}/current")
      data['data']
    rescue => e
      raise Puppet::Error, "Error while retrieving global configuration 'current': #{e}"
    end
  end

  # Update one part of the configuration referenced by the current resource (e.g. just the SMTP settings).
  #
  # To avoid lost updates, the provider ...
  #   * Fetches the current configuration from the remote instances
  #   * Merges the result of the `map_resource_to_config` hook with the current configuration
  #   * Updates the current configuration of the remote instance
  #
  def flush
    if @update_required
      update_global_config
      @property_hash = resource.to_hash
    end
  end

  # Update the global configuration. Intended to be used when updating multiple things with one flush invocation.
  #
  def update_global_config
    begin
      rest_resource = "#{@@global_config_rest_resource}/#{resource[:name]}"
      global_config = Nexus::Rest.get_all(rest_resource)
      global_config['data'].merge!(map_resource_to_config)
      Nexus::Rest.update(rest_resource, global_config)
    rescue Exception => e
      raise Puppet::Error, "Error while updating global configuration '#{resource[:name]}': #{e}"
    end
  end

  # Map the resource state to a partial global configuration. First this partial configuration is merged with the
  # current configuration returned by the REST resource. After that, the now complete configuration is send to the
  # REST resource in order to perform the update.
  #
  # This method is expected to be implemented by inheriting classes.
  #
  # returns: The data in a format as expected by the REST resources just without the data wrapper.
  # {
  #    'securityRealms': {
  #      'attribute1': 'value1',
  #      'attribute2': 'value2',
  #      'attribute3': 'value3',
  #    },
  # }
  #
  def map_resource_to_config
    notice("Method 'map_resource_to_config' should be implemented")
  end

  # Mark the resource as dirty effectively forcing an update.
  #
  def mark_config_dirty
    @update_required = true
  end
end
