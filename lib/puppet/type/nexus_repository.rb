require 'pathname'
require 'uri'

Puppet::Type.newtype(:nexus_repository) do
  @doc = "Manages Nexus Repository through a REST API"

  proxy_only_properties = [
    :remote_storage,
    :remote_user_agent,
    :remote_additional_url_params,
    :remote_request_timeout,
    :remote_request_retries,
    :proxy_user,
    :proxy_pass,
    :proxy_nt_lan_host,
    :proxy_nt_lan_domain,
    :proxy_item_max_age,
    :proxy_not_found_cache_ttl,
    :proxy_artifact_max_age,
    :proxy_metadata_max_age,
    :proxy_item_max_age,
  ]

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
      fail("Invalid local_storage_url #{value}; expected either 'default', absolute path or an URI matching the file scheme (file:///...).") unless \
        value.nil? or Pathname.new(value).absolute? or URI.parse(value).scheme == 'file'
    end
  end

  newproperty(:download_remote_indexes, :boolean => true) do
    desc 'Indicates if the index stored on the remote repository should be downloaded and used for local searches. Applicable for proxy repositories only. ' \
         'Only useful for proxy-type repositories.'
    defaultto :false
    munge { |value| @resource.munge_boolean(value) }
  end

  # proxy-specific #
  newproperty(:remote_storage) do
    desc 'This is the location of the remote repository being proxied. Only HTTP/HTTPs urls are currently supported. ' \
         'Only useful for proxy-type repositories.'
  end

  newproperty(:remote_user_agent) do
    desc 'A custom fragment to add to the "user-agent" string used in HTTP requests. ' \
         'Only useful for proxy-type repositories.'
  end

  newproperty(:remote_additional_url_params) do
    desc 'These are additional parameters sent along with the HTTP request. ' \
         'They are appended to the url along with a \'?\'. So \'foo=bar&foo2=bar2\' becomes \'HTTP://myurl?foo=bar&foo2=bar2\' ' \
         'Only useful for proxy-type repositories.'
  end

  newproperty(:remote_request_timeout) do
    desc 'Time Nexus will wait for a successful connection before retrying. (seconds) ' \
         'Only useful for proxy-type repositories.'
  end

  newproperty(:remote_request_retries) do
    desc 'Nexus will make this many connection attempts before giving up. ' \
         'Only useful for proxy-type repositories.'
  end

  newproperty(:proxy_item_max_age) do
    desc 'Repositories may contain resources that are neither artifacts identified by GAV coordinates or metadata. ' \
         'This value controls how long to cache such items in the repository before rechecking the remote repository. ' \
         'Only useful for proxy-type repositories.'
    #defaultto 1440
    munge { |value| Integer(value) }
  end

  newproperty(:proxy_not_found_cache_ttl) do
    desc 'This controls how long to cache the fact that a file was not found in the repository. ' \
         'Only useful for proxy-type repositories.'
    munge { |value| Integer(value) }
  end

  newproperty(:proxy_artifact_max_age) do
    desc 'This controls how long to cache the artifacts in the repository before rechecking the remote repository. ' \
         'In a release repository, this value should be -1 (infinite) as release artifacts shouldn\'t change. ' \
         'Only useful for proxy-type repositories.'
    munge { |value| Integer(value) }
  end

  newproperty(:proxy_metadata_max_age) do
    desc 'This controls how long to cache the metadata in the repository before rechecking the remote repository. ' \
         'Unlike artifact max age, this value should not be infinite or Maven won\'t discover new artifact releases.' \
         'Only useful for proxy-type repositories.'
    munge { |value| Integer(value) }
  end

  newproperty(:proxy_user) do
    desc 'The username used for authentication to the remote repository. ' \
         'Only useful for proxy-type repositories.'
  end

  newproperty(:proxy_pass) do
    desc 'The password used for authentication to the remote repository. ' \
         'Only useful for proxy-type repositories.'
  end

  newproperty(:proxy_nt_lan_host) do
    desc 'The Windows NT Lan Manager for authentication to the remote repository. ' \
         'Only useful for proxy-type repositories.'
  end

  newproperty(:proxy_nt_lan_domain) do
    desc 'The Windows NT Lan Manager domain for authentication to the remote repository. ' \
         'Only useful for proxy-type repositories.'
  end

  autorequire(:file) do
    Nexus::Config::file_path
  end

  def munge_boolean(value)
    return :true if [true, "true", :true].include? value
    return :false if [false, "false", :false].include? value
    fail("Expected boolean parameter, got '#{value}'")
  end

  validate do
    if self[:ensure] == :present
      if self[:type] != :proxy
        proxy_only_properties.each do |property|
          raise ArgumentError, "\'#{property}\' must not be set if type is not :proxy (value is #{self[property]})." if nil != self[property]
        end
      else
        raise ArgumentError, '\'remote_storage\' must be set if type is :proxy' if nil == self[:remote_storage]
      end
    end
  end

end
