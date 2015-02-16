require 'pathname'
require 'uri'

Puppet::Type.newtype(:nexus_repository) do
  @doc = "Manages Nexus Repository through a REST API"

  proxy_only_properties = [
    :remote_storage,
    :remote_auto_block,
    :remote_checksum_policy,
    :remote_download_indexes,
    :remote_file_validation,
    :remote_item_max_age,
    :remote_artifact_max_age,
    :remote_metadata_max_age,
    :remote_request_timeout,
    :remote_request_retries,
    :remote_query_string,
    :remote_user_agent,
    :remote_user,
    :remote_password_ensure,
    :remote_password,
    :remote_ntlm_host,
    :remote_ntlm_domain
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
    newvalues(:maven1, :maven2, :nuget, :site, :obr, :npm, :rubygems)
  end

  newproperty(:policy) do
    desc 'Repositories can store either only release or snapshot artefacts.'
    defaultto do [:maven1, :maven2].include?(@resource[:provider_type]) ? :release : :mixed end
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

  # proxy-specific #
  newproperty(:remote_storage) do
    desc 'This is the location of the remote repository being proxied. Only HTTP/HTTPs urls are currently supported. ' \
         'Only useful for proxy-type repositories.'
  end

  newproperty(:remote_download_indexes, :boolean => true) do
    desc 'Indicates if the index stored on the remote repository should be downloaded and used for local searches. Applicable for proxy repositories only. ' \
         'Only useful for proxy-type repositories.'
    defaultto do @resource[:type] == :proxy ? :true : nil end
    munge { |value| @resource.munge_boolean(value) }
  end
  
  newproperty(:remote_auto_block, :boolean => true) do
    desc 'Flag to enable Auto Blocking for this proxy repository. If enabled, Nexus will auto-block outbound ' \
         'connections on this repository if remote peer is detected as unreachable/unresponsive. Auto-blocked ' \
         'repositories will still try to detect remote peer availability, and will auto-unblock the proxy if ' \
         'remote peer detected as reachable/healthy. Auto-blocked repositories behaves exactly the same as user ' \
         'blocked proxy repositories, except they will auto-unblock themselves too. ' \
         'Only useful for proxy-type repositories.'
    defaultto do @resource[:type] == :proxy ? :true : nil end
    munge { |value| @resource.munge_boolean(value) }
  end

  newproperty(:remote_file_validation, :boolean => true) do
    desc 'Flag to check the remote file\'s content to see if it is valid. (e.g. not html error page), ' \
         'handy when you cannot enable strict checksum checking. ' \
         'Only useful for proxy-type repositories.'
    defaultto do @resource[:type] == :proxy ? :true : nil end
    munge { |value| @resource.munge_boolean(value) }
  end

  newproperty(:remote_checksum_policy) do
    desc 'The checksum policy for this repository: ' \
         ':ignore: Don\'t check remote checksums. ' \
         ':warn: Log a warning if the checksum is bad but serve the artifact anyway. ' \
         '(Default...there are currently known checksum errors on Central). ' \
         ':strict_if_exists: Do not serve the artifact if the checksum exists but is invalid. ' \
         ':strict: Require that a checksum exists on the remote repository and that it is valid. ' \
         'Only useful for proxy-type repositories.'
    defaultto do @resource[:type] == :proxy ? :warn : nil end
    newvalues(:ignore, :warn, :strict_if_exists, :strict)
  end
  
  newproperty(:remote_user) do
    desc 'The username used for authentication to the remote repository. ' \
         'Only useful for proxy-type repositories.'
  end

  newproperty(:remote_password_ensure) do
    desc 'The state of the password used for authentication to the remote repository. ' \
         'Either `absent` or `present` whereas `absent` means no password at all and ' \
         '`present` will update the password to the given `remote_password_value` field. ' \
         'Unfortunately, it is not possible to retrieve the current password.' \
         'Only useful for proxy-type repositories.'
    newvalues(:absent, :present)
  end

  newparam(:remote_password) do
    desc 'The password used for authentication to the remote repository. ' \
         'Will be only used if `remote_password` is set to `present`. ' \
         'Only useful for proxy-type repositories.'
    desc 'The expected value of the password. Will be only used if `password` is set to `present`.'
  end

  newproperty(:remote_ntlm_host) do
    desc 'The Windows NT Lan Manager for authentication to the remote repository. ' \
         'Only useful for proxy-type repositories.'
  end

  newproperty(:remote_ntlm_domain) do
    desc 'The Windows NT Lan Manager domain for authentication to the remote repository. ' \
         'Only useful for proxy-type repositories.'
  end

  newproperty(:remote_artifact_max_age) do
    desc 'This controls how long to cache the artifacts in the repository before rechecking the remote repository. (minutes) ' \
         'In a release repository, this value should be -1 (infinite) as release artifacts shouldn\'t change. ' \
         'Only useful for proxy-type repositories.'
    defaultto do @resource[:type] == :proxy ? -1 : nil end
    munge { |value| Integer(value) }
  end

  newproperty(:remote_metadata_max_age) do
    desc 'This controls how long to cache the metadata in the repository before rechecking the remote repository. (minutes) ' \
         'Unlike artifact max age, this value should not be infinite or Maven won\'t discover new artifact releases.' \
         'Only useful for proxy-type repositories.'
    defaultto do @resource[:type] == :proxy ? 1440 : nil end
    munge { |value| Integer(value) }
  end

  newproperty(:remote_item_max_age) do
    desc 'Repositories may contain resources that are neither artifacts identified by GAV coordinates or metadata. (minutes) ' \
         'This value controls how long to cache such items in the repository before rechecking the remote repository. ' \
         'Only useful for proxy-type repositories.'
    defaultto do @resource[:type] == :proxy ? 1440 : nil end
    munge { |value| Integer(value) }
  end

  newproperty(:remote_user_agent) do
    desc 'A custom fragment to add to the "user-agent" string used in HTTP requests. ' \
         'Only useful for proxy-type repositories.'
  end

  newproperty(:remote_query_string) do
    desc 'These are additional parameters sent along with the HTTP request. ' \
         'They are appended to the url along with a \'?\'. So \'foo=bar&foo2=bar2\' becomes \'HTTP://myurl?foo=bar&foo2=bar2\' ' \
         'This property is partially broken due to the ruby RestClient library ' \
         'Only useful for proxy-type repositories.'
  end

  newproperty(:remote_request_timeout) do
    desc 'Time Nexus will wait for a successful connection before retrying. (seconds) ' \
         'Only useful for proxy-type repositories.'
    defaultto do @resource[:type] == :proxy ? 60 : nil end
    munge { |value| Integer(value) }
  end

  newproperty(:remote_request_retries) do
    desc 'Nexus will make this many connection attempts before giving up. ' \
         'Only useful for proxy-type repositories.'
    defaultto do @resource[:type] == :proxy ? 10 : nil end
    munge { |value| Integer(value) }
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
      if ![:maven1, :maven2].include?(self[:provider_type])
        raise ArgumentError, "\'policy' must be 'mixed' if 'provider_type' is not ':maven1' or ':maven2'" if :mixed != self[:policy]
      end
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
