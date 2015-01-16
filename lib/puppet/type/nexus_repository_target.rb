require 'uri'

Puppet::Type.newtype(:nexus_repository_target) do
  @doc = "Manages Nexus Repository Target through a REST API"

  ensurable

  newparam(:name, :namevar => true) do
    desc 'Unique Repository Target identifier; once created cannot be changed unless the Repository Target is destroyed. The Nexus UI will not show this value.'
  end

  newproperty(:label) do
    desc 'Human readable label of the Repository Target. The Nexus UI will show it as Name.'
  end

  newproperty(:provider_type) do
    desc 'The content provider of the Repository Target. The Nexus UI will show this as Repository Type'
    defaultto :maven2
    validate do |value|
      raise ArgumentError, 'must be a non-empty string' if value.to_s.empty?
    end
  end

  newproperty(:patterns, :array_matching => :all) do
    desc 'List of regular expressions used to match the artifact paths that qualify for this repository target'
    defaultto []
    validate do |value|
      unless value.empty?
        raise ArgumentError, "patterns in repository target must be provided in an array" if value.include?(',')
      end
    end
  end

  validate do
    raise ArgumentError, "patterns must not be empty" if self[:ensure] == :present and (self[:patterns].empty?)
    raise ArgumentError, "label must not be empty" if self[:ensure] == :present and (self[:label].empty?)
  end

  autorequire(:file) do
    Nexus::Config::file_path
  end
end
