require 'uri'

Puppet::Type.newtype(:nexus_repository_target) do
  @doc = "Manages Nexus Repository Target through a REST API"

  ensurable

  newparam(:name, :namevar => true) do
    desc 'Unique repository target identifier; once created cannot be changed unless the repository target is destroyed. The Nexus UI will not show this value.'
  end

  newproperty(:label) do
    desc 'Human readable label of the repository target. The Nexus UI will show it as Name.'
  end

  newproperty(:provider_type) do
    desc 'The content provider of the repository target. The Nexus UI will show this as Repository Type'
    defaultto :maven2
    newvalues(:maven1, :maven2, :nuget, :obr, :p2, :site)
  end

  newproperty(:download_remote_indexes, :boolean => true) do
    desc 'Indicates if the index stored on the remote repository should be downloaded and used for local searches. Applicable for proxy repositories only.'
    defaultto :false
    munge { |value| @resource.munge_boolean(value) }
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

end
