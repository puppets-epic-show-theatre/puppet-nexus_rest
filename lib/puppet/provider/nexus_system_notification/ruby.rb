require 'json'
require File.join(File.dirname(__FILE__), '..', 'nexus_global_config')

Puppet::Type.type(:nexus_system_notification).provide(:ruby, :parent => Puppet::Provider::NexusGlobalConfig) do
  desc "Ruby-based management of the Nexus system notifications."
  
  confine :feature => :restclient
  
  def self.map_config_to_resource_hash(global_config)
    notification_settings = global_config['systemNotificationSettings']
    {
      :enabled => notification_settings['enabled'].to_s.intern,
      :emails  => notification_settings['emailAddresses'],
      :roles   => notification_settings['roles'].join(',')
    }
  end

  def map_resource_to_config
    {
      'systemNotificationSettings' => {
        'enabled'        => resource[:enabled] == :true,
        'emailAddresses' => resource[:emails],
        'roles'          => resource[:roles].split(',')
      }
    }
  end

  mk_resource_methods

  def enabled=(value)
    mark_config_dirty
  end

  def emails=(value)
    mark_config_dirty
  end

  def roles=(value)
    mark_config_dirty
  end
end
