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
    munge { |value| super(value).to_s.intern }
  end

  newproperty(:emails, :parent => Puppet::Property::List) do
    desc 'A list of email addresses to notify. Multiple email addresses should be specified as an array.'
    defaultto []
    validate do |value|
      unless value.empty?
        raise ArgumentError, "Invalid email address '#{value}'." if value !~ /@/
        raise ArgumentError, "Multiple email addresses must be provided as an array, not a comma-separated list." if value.include?(",")
      end
    end
    def membership
      :inclusive_membership
    end
  end

  newproperty(:roles, :parent => Puppet::Property::List) do
    desc 'A list of roles to notify. Multiple roles should be specified as an array.'
    defaultto []
    validate do |value|
      unless value.empty?
        raise ArgumentError, "Multiple roles must be provided as an array, not a comma-separated list." if value.include?(",")
      end
    end
    def membership
      :inclusive_membership
    end
  end

  newparam(:inclusive_membership) do
    desc "The list is considered a complete lists as opposed to minimum lists."
    newvalues(:inclusive)
    defaultto :inclusive
  end

  autorequire(:file) do
    Nexus::Config::file_path
  end

  # establish a happens-before relationship to other resources that update the same configuration; following the order
  # in which they are defined in the REST response
  autorequire(:nexus_connection_settings) do
    self[:name]
  end
end
