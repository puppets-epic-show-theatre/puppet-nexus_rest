require 'json'
require File.join(File.dirname(__FILE__), '..', 'nexus_global_config')

Puppet::Type.type(:nexus_proxy_settings).provide(:ruby, :parent => Puppet::Provider::NexusGlobalConfig) do
  desc "Ruby-based management of the global proxy settings."
  
  confine :feature => :restclient
  
  def self.map_config_to_resource_hash(global_config)
    proxy_settings = global_config['remoteProxySettings']
    {
      :http_proxy_enabled   => proxy_settings['httpProxySettings'] ? :true : :false,
      :http_proxy_hostname  => proxy_settings['httpProxySettings'] ? proxy_settings['httpProxySettings']['proxyHostname'] : :absent,
      :http_proxy_port      => proxy_settings['httpProxySettings'] ? proxy_settings['httpProxySettings']['proxyPort'] : :absent,
      :https_proxy_enabled  => proxy_settings['httpsProxySettings'] ? :true : :false,
      :https_proxy_hostname => proxy_settings['httpsProxySettings'] ? proxy_settings['httpsProxySettings']['proxyHostname'] : :absent,
      :https_proxy_port     => proxy_settings['httpsProxySettings'] ? proxy_settings['httpsProxySettings']['proxyPort'] : :absent,
      :non_proxy_hostnames  => proxy_settings['nonProxyHosts'] ? proxy_settings['nonProxyHosts'].join(',') : ''
    }
  end

  def map_resource_to_config
    proxy_settings = {
      'nonProxyHosts' => resource[:non_proxy_hostnames].split(',')
    }
    if resource[:http_proxy_enabled] == :true
      proxy_settings['httpProxySettings'] = {
        'proxyHostname' => resource[:http_proxy_hostname],
        'proxyPort'     => resource[:http_proxy_port]
      }
    end
    if resource[:https_proxy_enabled] == :true
      proxy_settings['httpsProxySettings'] = {
        'proxyHostname' => resource[:https_proxy_hostname],
        'proxyPort'     => resource[:https_proxy_port]
      }
    end
    { 'remoteProxySettings' => proxy_settings }
  end

  mk_resource_methods

  def http_proxy_enabled=(value)
    mark_config_dirty
  end

  def http_proxy_hostname=(value)
    mark_config_dirty
  end

  def http_proxy_port=(value)
    mark_config_dirty
  end

  def https_proxy_hostname=(value)
    mark_config_dirty
  end

  def https_proxy_port=(value)
    mark_config_dirty
  end

  def non_proxy_hostnames=(value)
    mark_config_dirty
  end
end
