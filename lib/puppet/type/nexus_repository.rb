Puppet::Type.newtype(:nexus_repository) do
  @doc = "Manages Nexus Repository through a REST API"

  ensurable

  newparam(:name, :namevar => true) do
  end
  newproperty(:baseurl) do
    desc "Base URL of service managing the resource"
  end
  newproperty(:resource) do
    desc "Path to the REST resource, eg. '/api/users'"
  end
  newproperty(:timeout) do
    desc "Time in seconds to wait for a response"
    defaultto 60
  end
end