require 'puppet/property/list'

Puppet::Type.newtype(:nexus_staging_ruleset) do
  @doc = 'Rules that can be associated with Nexus staging profiles.'

  ensurable

  newparam(:name, :namevar => true) do
    desc 'The name of the rule set.'
  end

  newparam(:id) do
    desc 'A read-only parameter set by the nexus_stating_ruleset resource.'
  end

  newproperty(:description) do
    desc 'The description of the rule set.'
    defaultto ''
  end

  newproperty(:rules, :parent => Puppet::Property::List) do
    desc 'The type of rules to be applied. Can be the type name (as shown in the user interface) or the type id. The
      plugin ships a list of known type names; if a type name is not known, it is passed unmodified to Nexus.'
    validate do |value|
      raise ArgumentError, 'Rules must not be empty' if value.to_s.empty?
      raise ArgumentError, 'Multiple rules must be provided as an array, not a comma-separated list.' if value.to_s.include?(',')
    end
    def membership
      :inclusive_membership
    end
  end

  validate do
    if self[:ensure] == :present
      raise ArgumentError, 'Rules is a mandatory property' if self[:rules].nil?
      raise ArgumentError, 'Rules must not be empty' if self[:rules].to_s.empty?
    end
  end

  newparam(:inclusive_membership) do
    desc 'The list is considered a complete lists as opposed to minimum lists.'
    newvalues(:inclusive)
    defaultto :inclusive
  end

  autorequire(:file) do
    Nexus::Config::file_path
  end
end
