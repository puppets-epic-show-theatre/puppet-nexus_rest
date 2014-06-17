require 'puppet/property/boolean'
require 'puppet/property/list'

Puppet::Type.newtype(:nexus_proxy_settings) do
  @doc = 'Manage the default HTTP proxy settings.'

  newparam(:name, :namevar => true) do
    desc 'Name of the configuration (i.e. current).'
  end

  newproperty(:http_proxy_enabled, :parent => Puppet::Property::Boolean) do
    desc 'Turn on the HTTP proxy for remote connections. Requires that `http_proxy_hostname` and `http_proxy_port` are
      configured as well.'
    defaultto :false
    munge { |value| super(value).to_s.intern }
  end

  newproperty(:http_proxy_hostname) do
    desc 'The hostname of the HTTP proxy used for remote connections (just the hostname, no protocol).'
    validate do |value|
      raise ArgumentError, 'Proxy hostname must not be empty' if value.nil? or value.to_s.empty?
    end
  end

  newproperty(:http_proxy_port) do
    desc 'The port number of the HTTP proxy used for remote connections.'
    validate do |value|
      raise ArgumentError, "Proxy port must be a non-negative integer, got #{value}" unless value.to_s =~ /\d+/
      raise ArgumentError, "Proxy port must within [1, 65535], got #{value}" unless (1..65535).include?(value.to_i)
    end
    munge { |value| Integer(value) }
  end

  newproperty(:https_proxy_enabled, :parent => Puppet::Property::Boolean) do
    desc 'Turn on the HTTPS proxy for remote connections. Requires that a HTTP proxy is configured and
      `https_proxy_hostname` and `https_proxy_port` are set as well.'
    defaultto :false
    munge { |value| super(value).to_s.intern }
  end

  newproperty(:https_proxy_hostname) do
    desc 'The hostname of the HTTPS proxy used for remote connections (just the hostname, no protocol).'
    validate do |value|
      raise ArgumentError, 'Proxy hostname must not be empty' if value.nil? or value.to_s.empty?
    end
  end

  newproperty(:https_proxy_port) do
    desc 'The port number of the HTTPS proxy used for remote connections.'
    validate do |value|
      raise ArgumentError, "Proxy port must be a non-negative integer, got #{value}" unless value.to_s =~ /\d+/
      raise ArgumentError, "Proxy port must within [1, 65535], got #{value}" unless (1..65535).include?(value.to_i)
    end
    munge { |value| Integer(value) }
  end

  newproperty(:non_proxy_hostnames, :parent => Puppet::Property::List) do
    desc 'A list of hosts that should not be accessed via the configured HTTP / HTTPS proxy. Regular expressions are supported, e.g. `*\.example\.com`'
    defaultto []
    validate do |value|
      unless value.empty?
        raise ArgumentError, "Multiple non-proxy hostnames must be provided as an array, not a comma-separated list." if value.include?(',')
      end
    end
    def membership
      :inclusive_membership
    end
  end

  newparam(:inclusive_membership) do
    desc 'The list is considered a complete lists as opposed to minimum lists.'
    newvalues(:inclusive)
    defaultto :inclusive
  end

  validate do
    fail('http_proxy_hostname is required when http_proxy_enabled is true') if self[:http_proxy_enabled] == :true and self[:http_proxy_hostname].nil?
    fail('http_proxy_port is required when http_proxy_enabled is true') if self[:http_proxy_enabled] == :true and self[:http_proxy_port].nil?
    fail('http_proxy_enabled is required when https_proxy_enabled is true') if self[:https_proxy_enabled] == :true and self[:http_proxy_enabled]  == :false
    fail('https_proxy_hostname is required when https_proxy_enabled is true') if self[:https_proxy_enabled] == :true and self[:https_proxy_hostname].nil?
    fail('https_proxy_port is required when https_proxy_enabled is true') if self[:https_proxy_enabled] == :true and self[:https_proxy_port].nil?
  end

  autorequire(:file) do
    Nexus::Config::file_path
  end

  # establish a happens-before relationship to other resources that update the same configuration; following the order
  # in which they are defined in the REST response
  autorequire(:nexus_smtp_settings) do
    self[:name]
  end
end
