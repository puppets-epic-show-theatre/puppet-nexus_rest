require 'puppet/property/boolean'
require 'puppet/property/list'

Puppet::Type.newtype(:nexus_system_notification) do
  @doc = 'Manage the global Nexus system notification settings through a REST API. System notifications are send when
    Nexus blocks or unblocks a proxy repository.'

  newparam(:name, :namevar => true) do
    desc 'Name of the configuration (i.e. current).'
  end

  newproperty(:enabled, :parent => Puppet::Property::Boolean) do
    desc 'Enable the system to send notifications to the configured recipients.'
    defaultto :false
  end

  newproperty(:emails, :parent => Puppet::Property::List) do
    desc 'A list of email addresses to notify. Multiple email addresses should be specified as an array.'
    validate do |value|
      unless value.empty?
        raise ArgumentError, "Invalid email address '#{value}'." if value !~ /@/
      end
    end
  end

  newproperty(:roles, :parent => Puppet::Property::List) do
    desc 'A list of roles to notify. Multiple roles should be specified as an array.'
  end

  autorequire(:file) do
    Nexus::Config::CONFIG_FILENAME
  end
end
