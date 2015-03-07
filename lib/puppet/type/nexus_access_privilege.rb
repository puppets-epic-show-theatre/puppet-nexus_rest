Puppet::Type.newtype(:nexus_access_privilege) do
  @doc = "Manages Nexus Access Privileges through a REST API"

  ensurable

  newparam(:name, :namevar => true) do
    desc 'Unique Privilege identifier; once created cannot be changed unless the Privilege is destroyed. Nexus UI will append method names to the end of this value.'
    validate do |value|
      raise ArgumentError, 'must not contain spaces' if value.to_s.include? ' '
    end
  end

  newparam(:id) do
    desc 'Random identifier generated by Nexus used to reference the privilege, read-only.'
  end

  newproperty(:description) do
    desc 'The description of this privilege.'
    validate do |value|
      raise ArgumentError, 'must be a non-empty string or not set' if value && value.empty?
    end
  end

  newproperty(:methods) do
    desc 'Operations that this privilege will be granted'

    valid_methods = ['create', 'update', 'read', 'delete']
    error_message = "methods must one or more of these values: #{valid_methods}"

    validate do |value|
      raise ArgumentError, error_message if !value or value.empty?
      value = value.split(',') if value.kind_of?(String)
      value.each do |operation|
        raise ArgumentError, error_message unless valid_methods.include? operation
      end
    end
  end

  newproperty(:repository_target) do
    desc 'The Repository Target that will be applied with this privilege'
    validate do |value|
      raise ArgumentError, 'must be a non-empty string' if value.to_s.empty?
    end
  end

  newproperty(:repository) do
    desc 'The Repository this privilege will be associated with.'
    defaultto ''
  end

  newproperty(:repository_group) do
    desc 'The Repository Group this privilege will be associated with.'
    defaultto ''
  end

  validate do
    raise ArgumentError, 'either repository or repository_group must be specified (but not both)' if self[:repository].empty? and self[:repository_group].empty?
    raise ArgumentError, 'repository and repository_group must not both be specified' if !self[:repository].empty? and !self[:repository_group].empty?
  end

  autorequire(:file) do
    Nexus::Config::file_path
  end

  autorequire(:nexus_repository_target) do
    self[:repository_target]
  end

  autorequire(:nexus_repository) do
    self[:repository]
  end

  autorequire(:nexus_repository_group) do
    self[:repository_group]
  end
end
