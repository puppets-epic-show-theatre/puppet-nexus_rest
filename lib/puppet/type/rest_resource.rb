Puppet::Type.newtype(:rest_resource) do
  @doc = "Manages a resource through a REST API"

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