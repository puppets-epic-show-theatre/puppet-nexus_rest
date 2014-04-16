Puppet::Type.newtype(:nexus_repository) do
  @doc = "Manages Nexus Repository through a REST API"

  ensurable

  newparam(:name, :namevar => true) do
    desc 'Unique repository identifier; once created cannot be changed unless the repository is destroyed. The Nexus UI will show it as repository id.'
  end

  newproperty(:label) do
    desc 'Human readable label of the repository. The Nexus UI will show it as repository name.'
  end

  newproperty(:provider_type) do
    desc 'The content provider of the repository'
    newvalues('maven1', 'maven2')
  end

  autorequire(:file) do
    Nexus::Config::CONFIG_FILENAME
  end
end