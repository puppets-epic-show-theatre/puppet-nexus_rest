require 'cgi'
require 'json'
require File.join(File.dirname(__FILE__), '..', 'nexus_global_config')

Puppet::Type.type(:nexus_connection_settings).provide(:ruby, :parent => Puppet::Provider::NexusGlobalConfig) do
  desc "Ruby-based management of the global connection settings."
  
  confine :feature => :restclient
  
  def self.map_config_to_resource_hash(global_config)
    connection_settings = global_config['globalConnectionSettings']
    {
      :timeout             => connection_settings['connectionTimeout'],
      :retries             => connection_settings['retrievalRetryCount'],
      :query_string        => connection_settings['queryString'] ? CGI.unescapeHTML(connection_settings['queryString']) : '',
      :user_agent_fragment => connection_settings['userAgentString'] ? connection_settings['userAgentString'] : ''
    }
  end

  def map_resource_to_config
    connection_settings = {
      'connectionTimeout'   => resource[:timeout],
      'retrievalRetryCount' => resource[:retries]
    }
    connection_settings['queryString'] = resource[:query_string] unless resource[:query_string].empty?
    connection_settings['userAgentString'] = resource[:user_agent_fragment] unless resource[:user_agent_fragment].empty?
    { 'globalConnectionSettings' => connection_settings }
  end

  mk_resource_methods

  def timeout=(value)
    mark_config_dirty
  end

  def retries=(value)
    mark_config_dirty
  end

  def query_string=(value)
    mark_config_dirty
  end

  def user_agent_fragment=(value)
    mark_config_dirty
  end
end
