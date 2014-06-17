require 'puppet/property/boolean'

Puppet::Type.newtype(:nexus_smtp_settings) do
  @doc = 'Manage the global Nexus SMTP settings.'

  newparam(:name, :namevar => true) do
    desc 'Name of the configuration (i.e. current).'
  end

  newproperty(:hostname) do
    desc 'The host name of the SMTP server.'
    validate do |value|
      raise ArgumentError, "Hostname must not be empty" if value.nil? or value.to_s.empty?
    end
  end

  newproperty(:port) do
    desc 'The port number the SMTP server is listening on. Must be within 1 and 65535.'
    defaultto 25
    validate do |value|
      raise ArgumentError, "Port must be a non-negative integer, got #{value}" unless value.to_s =~ /\d+/
      raise ArgumentError, "Port must within [1, 65535], got #{value}" unless (1..65535).include?(value.to_i)
    end
    munge { |value| Integer(value) }
  end

  newproperty(:username) do
    desc 'The username used to access the SMTP server.'
    defaultto ''
  end

  newproperty(:password) do
    desc 'The state of the password used to access the SMTP server. Either `absent` or `present` whereas `absent` means
      no password at all and `present` will update the password to the given `password_value` field. Unfortunately, it
      is not possible to retrieve the current password.'
    defaultto :absent
    newvalues(:absent, :present)
  end

  newparam(:password_value) do
    desc 'The expected value of the password. Will be only used if `password` is set to `present`.'
    defaultto 'secret'
  end

  newproperty(:communication_security) do
    desc 'Enable the selected communication security when talking to the SMTP server. Can be one of: `none`, `ssl` or
      `tls`.'
    defaultto :none
    newvalues(:none, :ssl, :tls)
  end

  newproperty(:sender_email) do
    desc 'Email address used in the `From:` field.'
    validate do |value|
      raise ArgumentError, "Sender email must not be empty" if value.nil? or value.to_s.empty?
      raise ArgumentError, "Invalid email address '#{value}'." if value !~ /@/
    end
  end

  newproperty(:use_nexus_trust_store, :parent => Puppet::Property::Boolean) do
    desc 'When using SSL to communicate with the SMTP server, trust is based on Nexus\' internal certifacte store. Only
      valid for SSL connections (see `communication_security`).'
    munge { |value| super(value).to_s.intern }
  end

  autorequire(:file) do
    Nexus::Config::file_path
  end

  # establish a happens-before relationship to other resources that update the same configuration; following the order
  # in which they are defined in the REST response
  autorequire(:nexus_system_notifications) do
    self[:name]
  end
end
