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
    newvalues(:hosted, :proxy, :virtual)
  end

  newproperty(:provider_type) do
    desc 'The content provider of the repository'
    newvalues(:maven1, :maven2, :nuget, :site, :obr)
  end

  newproperty(:policy) do
    desc 'Repositories can store either only release or snapshot artefacts.'
    newvalues(:SNAPSHOT, :RELEASE, :MIXED)
  end

  newproperty(:exposed, :boolean => true) do
    desc 'Controls if the repository is remotely accessible. Responds to the \'Publish URL\' setting in the UI.'
    munge { |value| @resource.munge_boolean(value) }
  end

  newproperty(:write_policy) do
    desc 'Controls if users are allowed to deploy and/or update artifacts in this repositoy. Responds to the \'Deployment Policy\' setting in the UI and is applicable for hosted repositories only.'
    newvalues(:READ_ONLY, :ALLOW_WRITE_ONCE, :ALLOW_WRITE)
  end

  newproperty(:browseable, :boolean => true) do
    desc 'Controls if users can browse the contents of repository via their web browsers. Responds to the \'Allow File Browsing\' setting in the UI.'
    munge { |value| @resource.munge_boolean(value) }
  end

  newproperty(:indexable, :boolean => true) do
    desc 'Controls if the artifacts contained in this repository are index and thus searchable. Responds to the \'Include in Search\' setting in the UI.'
    munge { |value| @resource.munge_boolean(value) }
  end

  newproperty(:not_found_cache_ttl) do
    desc 'Controls how long to cache the fact that a file was not found in the repository.'
    munge { |value| Integer(value) }
  end

  newproperty(:local_storage_url) do
    desc 'Used to override the default local storage. Leave it blank to use the default. Should be a file URI.'
    validate do |value|
      fail("Invalid local_storage_url #{value}") unless value.empty? or URI.parse(value).scheme == 'file'
    end
  end

  newproperty(:download_remote_indexes, :boolean => true) do
    desc 'Indicates if the index stored on the remote repository should be downloaded and used for local searches. Applicable for proxy repositories only.'
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
