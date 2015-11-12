require 'json'
require File.join(File.dirname(__FILE__), '..', 'nexus_global_config')

Puppet::Type.type(:nexus_application_server_settings).provide(:ruby, :parent => Puppet::Provider::NexusGlobalConfig) do
  desc "Ruby-based management of the Nexus web application settings."
  
  confine :feature => :restclient
  
  def self.map_config_to_resource_hash(global_config)
    notification_settings = global_config['globalRestApiSettings']
    {
      :forceurl => notification_settings['forceBaseUrl'].to_s.intern,
      :baseurl  => notification_settings['baseUrl'],
      :timeout  => notification_settings['uiTimeout']
    }
  end

  def map_resource_to_config
    {
      'globalRestApiSettings' => {
        'forceBaseUrl' => resource[:forceurl] == :true,
        'baseUrl'      => resource[:baseurl],
        'uiTimeout'    => resource[:timeout]
      }
    }
  end

  mk_resource_methods

  def forceurl=(value)
    mark_config_dirty
  end

  def baseurl=(value)
    mark_config_dirty
  end

  def timeout=(value)
    mark_config_dirty
  end
end
