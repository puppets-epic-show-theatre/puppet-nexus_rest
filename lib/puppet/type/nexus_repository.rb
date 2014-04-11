Puppet::Type.newtype(:nexus_repository) do
  @doc = "Manages Nexus Repository through a REST API"

  PROVIDERS = ['maven1', 'maven2']

  ensurable

  newparam(:name, :namevar => true) do
  end

  newproperty(:provider_type) do
    desc 'The content provider of the repository'
    validate do |value|
      fail('value is not supported \'%s\'; valid values are: %s.' % [value, PROVIDERS.join(', ')]) unless PROVIDERS.include? value
    end
  end
end