require 'uri'
require 'puppet/property/boolean'

Puppet::Type.newtype(:nexus_repository_group) do
  @doc = "Manages Nexus Repository Group through a REST API"

  ensurable

  newparam(:name, :namevar => true) do
    desc 'Unique group identifier; once created cannot be changed unless the Repository Group is destroyed. The Nexus UI will show it as Group ID.'
  end

  newproperty(:label) do
    defaultto ''
    desc 'Human readable label of the Repository Group. The Nexus UI will show it as Group Name.'
  end

  newproperty(:provider_type) do
    desc 'The content provider of the Repository Group'
    defaultto :maven2
    newvalues(:maven1, :maven2, :nuget, :obr, :npm, :rubygems)
  end

  newproperty(:exposed, :parent => Puppet::Property::Boolean) do
    desc 'Controls if the Repository Group is remotely accessible. Responds to the \'Publish URL\' setting in the UI.'
    defaultto :true
    munge { |value| super(value).to_s.intern }
  end

  newproperty(:repositories, :array_matching => :all) do
    desc 'A list of repositories contained in this Repository Group'
    defaultto []
    validate do |value|
      unless value.empty?
        raise ArgumentError, "repositories in group must be provided in an array" if value.include?(',')
      end
    end
  end

  autorequire(:file) do
    Nexus::Config::file_path
  end

  autorequire(:nexus_repository) do
    self[:repositories] if self[:repositories] and self[:repositories].size() > 0
  end

  autorequire(:nexus_repository_group) do
    self[:repositories] if self[:repositories] and self[:repositories].size() > 0
  end

  validate do
    raise ArgumentError, "label must not be empty" if self[:ensure] == :present and (self[:label].empty?)
  end

end
