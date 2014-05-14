require 'puppet/property/boolean'
require 'puppet/property/list'

Puppet::Type.newtype(:nexus_global_settings) do
  @doc = 'Manage the global Nexus settings through a REST API'

  newparam(:name, :namevar => true) do
    desc 'Name of the global configuration (i.e. current or default)'
  end

  newproperty(:notification_enabled, :parent => Puppet::Property::Boolean) do
    desc 'Enable the system to send notifications to the configured recipients.'
    defaultto :false
  end

  newproperty(:notification_recipients, :parent => Puppet::Property::List) do
    desc 'A list of email addresses to notify.'
    validate do |value|
      unless value.empty?
        raise ArgumentError, "Invalid email address '#{value}'." if value !~ /@/
      end
    end
  end

  autorequire(:file) do
    Nexus::Config::CONFIG_FILENAME
  end
end
