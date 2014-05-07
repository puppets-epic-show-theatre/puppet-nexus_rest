require 'uri'

Puppet::Type.newtype(:nexus_repository) do
  @doc = "Manages Nexus Repository through a REST API"

  ensurable

  newparam(:name, :namevar => true) do
    desc 'Unique repository identifier; once created cannot be changed unless the repository is destroyed. The Nexus UI will show it as repository id.'
  end

  newproperty(:label) do
    desc 'Human readable label of the repository. The Nexus UI will show it as repository name.'
  end

  newproperty(:type) do
    desc 'Type of this repository. Can be hosted, proxy or virtual; cannot be changed after creation without deleting the repository.'
    defaultto :hosted
    newvalues(:hosted, :proxy, :virtual)
  end

  newproperty(:provider_type) do
    desc 'The content provider of the repository'
    defaultto :maven2
    newvalues(:maven1, :maven2, :nuget, :site, :obr)
  end

  newproperty(:policy) do
    desc 'Repositories can store either only release or snapshot artefacts.'
    # TODO: :release is only the default for Maven; for other repositories, the value is :mixed and cannot be changed
    defaultto :release
    newvalues(:snapshot, :release, :mixed)
  end

  newproperty(:exposed, :boolean => true) do
    desc 'Controls if the repository is remotely accessible. Responds to the \'Publish URL\' setting in the UI.'
    defaultto :true
    munge { |value| @resource.munge_boolean(value) }
  end

  newproperty(:write_policy) do
    desc 'Controls if users are allowed to deploy and/or update artifacts in this repository. Responds to the \'Deployment Policy\' setting in the UI and is applicable for hosted repositories only.'
    defaultto :allow_write_once
    newvalues(:read_only, :allow_write_once, :allow_write)
  end

  newproperty(:browseable, :boolean => true) do
    desc 'Controls if users can browse the contents of repository via their web browsers. Responds to the \'Allow File Browsing\' setting in the UI.'
    defaultto :true
    munge { |value| @resource.munge_boolean(value) }
  end

  newproperty(:indexable, :boolean => true) do
    desc 'Controls if the artifacts contained in this repository are index and thus searchable. Responds to the \'Include in Search\' setting in the UI.'
    defaultto :true
    munge { |value| @resource.munge_boolean(value) }
  end

  newproperty(:not_found_cache_ttl) do
    desc 'Controls how long to cache the fact that a file was not found in the repository (in minutes).'
    defaultto 1440
    munge { |value| Integer(value) }
  end

  newproperty(:local_storage_url) do
    desc 'Override the default local storage; should match the file URI scheme, set to undef to use the default location.'
    # TODO: add state transition from <value> to undef (currently no notification)
    validate do |value|
      fail("Invalid local_storage_url #{value}; expected either 'default' or an URI matching the file scheme.") unless value.nil? or URI.parse(value).scheme == 'file'
    end
  end

  newproperty(:download_remote_indexes, :boolean => true) do
    desc 'Indicates if the index stored on the remote repository should be downloaded and used for local searches. Applicable for proxy repositories only.'
    defaultto :false
    munge { |value| @resource.munge_boolean(value) }
  end

  autorequire(:file) do
    Nexus::Config::CONFIG_FILENAME
  end

  def munge_boolean(value)
    return :true if [true, "true", :true].include? value
    return :false if [false, "false", :false].include? value
    fail("Expected boolean parameter, got '#{value}'")
  end
end
