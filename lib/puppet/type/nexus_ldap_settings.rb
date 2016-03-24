Puppet::Type.newtype(:nexus_ldap_settings) do
  @doc = 'Manage the Nexus OSS LDAP connection settings.'

  def pre_run_check
    if self[:ldap_groups_as_roles]
      raise ArgumentError, "group_base_dn must not be empty when using ldap_groups_as_roles" if self[:group_base_dn].nil? or self[:group_base_dn].to_s.empty?
      raise ArgumentError, "group_id_attribute must not be empty when using ldap_groups_as_roles" if self[:group_id_attribute].nil? or self[:group_id_attribute].to_s.empty?
      raise ArgumentError, "group_member_attribute must not be empty when using ldap_groups_as_roles" if self[:group_member_attribute].nil? or self[:group_member_attribute].to_s.empty?
      raise ArgumentError, "group_member_format must not be empty when using ldap_groups_as_roles" if self[:group_member_format].nil? or self[:group_member_format].to_s.empty?
      raise ArgumentError, "group_object_class must not be empty when using ldap_groups_as_roles" if self[:group_object_class].nil? or self[:group_object_class].to_s.empty?
    end
  end

  newparam(:name, :namevar => true) do
    desc 'Name of the configuration (i.e. current).'
  end

  newproperty(:hostname) do
    desc 'The host name of the LDAP server.'
    validate do |value|
      raise ArgumentError, "Hostname must not be empty" if value.nil? or value.to_s.empty?
    end
  end

  newproperty(:port) do
    desc 'The port number the LDAP server is listening on. Must be within 1 and 65535.'
    defaultto 389
    validate do |value|
      raise ArgumentError, "Port must be a non-negative integer, got #{value}" unless value.to_s =~ /\d+/
      raise ArgumentError, "Port must within [1, 65535], got #{value}" unless (1..65535).include?(value.to_i)
    end
    munge { |value| Integer(value) }
  end

  newproperty(:username) do
    desc 'The username used to access the LDAP server.'
    defaultto ''
  end

  newproperty(:password) do
    desc 'The state of the password used to access the LDAP server. Either `absent` or `present` whereas `absent` means
      no password at all and `present` will update the password to the given `password_value` field. Unfortunately, it
      is not possible to retrieve the current password.'
    defaultto :absent
    newvalues(:absent, :present)
  end

  newparam(:password_value) do
    desc 'The expected value of the password. Will be only used if `password` is set to `present`.'
    defaultto 'secret'
  end

  newproperty(:protocol) do
    desc 'The LDAP protocol to use. Can be one of: `ldap` or `ldaps`.'
    defaultto :ldap
    newvalues(:ldaps, :ldap)
  end

  # need to find out what the other scheme values are

  newproperty(:authentication_scheme) do
    desc 'The authentication scheme protocol to use. Can be one of: `simple`, `none`, `DIGEST-MD5` or `CRAM-MD5`.'
    defaultto :none
    newvalues(:simple, :none, :DIGEST_MD5, :CRAM_MD5)
  end

  newproperty(:search_base) do
    desc 'The LDAP search base to use.'
    validate do |value|
      raise ArgumentError, "search_base must not be empty" if value.nil? or value.to_s.empty?
    end
  end

  newproperty(:realm) do
    desc 'The LDAP realm to use.'
    defaultto ''
  end

  newproperty(:ldap_filter) do
    desc 'The LDAP filter to use to filter users.'
    defaultto ''
  end

  newproperty(:email_address_attribute) do
    desc 'The LDAP attribute to use for email address.'
    defaultto 'email'
  end

  newproperty(:user_password_attribute) do
    desc 'The LDAP attribute to use for user password.'
    defaultto ''
  end

  newproperty(:user_id_attribute) do
    desc 'The LDAP attribute to use for user ID.'
    defaultto 'cn'
  end

  newproperty(:user_object_class) do
    desc 'The LDAP user object class.'
    defaultto 'user'
  end

  newproperty(:user_base_dn) do
    desc 'The LDAP user base DN.'
    defaultto 'OU=users'
  end

  newproperty(:user_real_name_attribute) do
    desc 'The LDAP attribute to use for user display name.'
    defaultto 'displayName'
  end

  newproperty(:user_subtree, :boolean => true) do
    desc 'Set to true if users are in a subtree under the user base DN.'
    defaultto false
  end

  newproperty(:group_base_dn) do
    desc 'The LDAP group base dn to use.'
    defaultto 'OU=groups'
  end

  newproperty(:group_id_attribute) do
    desc 'The LDAP group ID attribute to use.'
    defaultto 'cn'
  end

  newproperty(:group_member_attribute) do
    desc 'The LDAP group member attribute to use.'
    defaultto 'uniqueMember'
  end

  newproperty(:group_member_format) do
    desc 'The LDAP group member format to use.'
    defaultto '${dn}'
  end

  newproperty(:group_object_class) do
    desc 'The LDAP group object class to use.'
    defaultto 'group'
  end

  newproperty(:group_subtree, :boolean => true) do
    desc 'Set to true if groups are in a subtree under the group base DN.'
    defaultto false
  end

  newproperty(:ldap_groups_as_roles, :boolean => true) do
    desc 'Set to true if Nexus should map LDAP groups to roles.'
    defaultto false
  end

  autorequire(:file) do
    Nexus::Config::file_path
  end

  # establish a happens-before relationship to other resources that update the same configuration; following the order
  # in which they are defined in the REST response
  autorequire(:nexus_system_notifications) do
    self[:name]
  end
end
