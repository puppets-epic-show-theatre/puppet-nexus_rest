require 'json'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'config.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'exception.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'rest.rb'))

Puppet::Type.type(:nexus_system_notification).provide(:ruby) do
  desc "Ruby-based management of the Nexus system notifications."

  def initialize(value={}, dirty_flag = false)
    super(value)
    @dirty_flag = dirty_flag
  end

  def self.instances
    begin
      # we only support the current configuration; the other existing configuration - default - looks quite different
      [ map_data_to_resource('current', Nexus::Rest.get_all('/service/local/global_settings/current')) ]
    rescue => e
      raise Puppet::Error, "Error while retrieving settings: #{e}"
    end
  end

  def self.prefetch(resources)
    settings = instances
    resources.keys.each do |name|
      if provider = settings.find { |setting| setting.name == name }
        resources[name].provider = provider
      end
    end
  end

  def flush
    if @dirty_flag
      begin
        Nexus::Rest.update("/service/local/global_settings/#{resource[:name]}", map_resource_to_data)
      rescue Exception => e
        raise Puppet::Error, "Error while updating nexus_system_notification #{resource[:name]}: #{e}"
      end
      @property_hash = resource.to_hash
    end
  end

  def self.map_data_to_resource(name, settings)
    notification_settings = settings['data']['systemNotificationSettings']
    new(
      :name    => name,
      :enabled => notification_settings['enabled'].to_s.to_sym,
      :emails  => notification_settings['emailAddresses'],
      :roles   => notification_settings['roles'].join(',')
    )
  end

  # Returns the resource in a representation as expected by Nexus:
  #
  # {
  #   :data => {
  #              :id   => <resource name>
  #              :name => <resource label>
  #              ...
  #            }
  # }
  def map_resource_to_data
    {
      :data => {
        :systemNotificationSettings => {
          :enabled        => resource[:enabled],
          :emailAddresses => resource[:emails],
          :roles          => resource[:roles].split(',')
        }
      }
    }
  end

  mk_resource_methods

  def enabled=(value)
    mark_dirty
  end

  def mark_dirty
    @dirty_flag = true
  end
end
