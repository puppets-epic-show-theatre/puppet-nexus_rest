require 'uri'

Puppet::Type.newtype(:nexus_crowd_settings) do
  @doc = 'Manage the crowd settings.'

  newparam(:name, :namevar => true) do
    desc 'Name of the configuration (i.e. current).'
  end

  newproperty(:application_name) do
    desc 'The username of the crowd application.'

    validate do |value|
      raise ArgumentError, "application_name must be set" unless (value.is_a? String) and !value.empty?
    end
  end

  newproperty(:application_password) do
    desc 'The state of the application_password. Either `absent` or `present` whereas `absent` means
    no password at all and `present` will update the password to the given `password` field. Unfortunately, it is not
    possible to retrieve the current password.'
    defaultto :absent
    newvalues(:absent, :present)

  end

  newparam(:application_password_value) do
    desc 'The password for the application'

    validate do |value|
      raise ArgumentError, "application_password_value must be set" unless (value.is_a? String) and !value.empty?
    end
  end

  newproperty(:crowd_server_url) do
    desc 'The url of the crowd server'
    validate do |value|
      raise ArgumentError, "Base URL must not be empty" if value.nil? or value.to_s.empty?
      raise ArgumentError, "Base URL must be a valid url" unless URI.parse(value).is_a?(URI::HTTP) or URI.parse(value).is_a?(URI::HTTPS)
    end
  end

  newproperty(:http_timeout) do
    desc 'The HTTP connection timeout in seconds.'
    defaultto 60
    validate do |value|
      raise ArgumentError, "Timeout must be a non-negative integer, got #{value}" unless value.to_s =~ /\d+/
      raise ArgumentError, "Timeout must bigger than or equal to zero" unless value.to_i >= 0
    end
    munge { |value| Integer(value) }
  end
end