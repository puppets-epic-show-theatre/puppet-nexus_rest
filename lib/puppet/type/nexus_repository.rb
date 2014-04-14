Puppet::Type.newtype(:nexus_repository) do
  @doc = "Manages Nexus Repository through a REST API"

  ensurable

  newparam(:name, :namevar => true) do
  end

  newproperty(:provider_type) do
    desc 'The content provider of the repository'
    newvalues('maven1', 'maven2')
  end
end