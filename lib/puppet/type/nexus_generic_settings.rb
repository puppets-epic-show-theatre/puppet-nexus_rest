Puppet::Type.newtype(:nexus_generic_settings) do
  @doc = 'Manage any Nexus settings available with the REST API.'

  newparam(:name, :namevar => true) do
    desc 'Name of the configuration (i.e. current).'
  end

  newproperty(:api_url_fragment) do
    desc 'The Nexus API to use - do not include base URL.'
    validate do |value|
      raise ArgumentError, "api_url_fragment must not be empty" if value.nil? or value.to_s.empty?
    end
  end

  newproperty(:settings_hash) do
    desc 'Hash of settings which will map to the input expected by the REST API.'
    validate do |value|
      raise ArgumentError, "settings_hash must not be empty" if value.nil?
    end
  end

  newproperty(:merge, :boolean => true) do
    desc 'Set to true if settings_hash should be merged onto the existing settings for this API call.'
    defaultto false
  end

  newproperty(:action) do
    desc 'The action to perform. Can be `create` (to use the API POST method if the item does not already exist) or  `update` (to use the API PUT method).'
    defaultto :update
    newvalues(:update, :create)
  end

  newproperty(:id_field) do
    desc 'The unique ID field for the object type (when using action = create)'
    defaultto 'id'
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
