require 'puppet/property/boolean'
require 'uri'

Puppet::Type.newtype(:nexus_application_server_settings) do
  @doc = 'Manage the global Nexus application server settings.'

  newparam(:name, :namevar => true) do
    desc 'Name of the configuration (i.e. current).'
  end

  newproperty(:baseurl) do
    desc 'The base URL of the Nexus web application.'
    validate do |value|
      raise ArgumentError, "Base URL must not be empty" if value.nil? or value.to_s.empty?
      raise ArgumentError, "Base URL must be a valid url" unless URI.parse(value).is_a?(URI::HTTP) or URI.parse(value).is_a?(URI::HTTPS)
    end
  end

  newproperty(:forceurl, :parent => Puppet::Property::Boolean) do
    desc 'When set to `true` will force all URLs to be built with the `baseurl`. Otherwise the `baseurl` will only be
      used in emails and rss feeds.'
    defaultto :false
    munge { |value| super(value).to_s.intern }
  end

  newproperty(:timeout) do
    desc 'The HTTP connection timeout in seconds.'
    defaultto 60
    validate do |value|
      raise ArgumentError, "Timeout must be a non-negative integer, got #{value}" unless value.to_s =~ /\d+/
      raise ArgumentError, "Timeout must bigger than or equal to zero" unless value.to_i >= 0
    end
    munge { |value| Integer(value) }
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
