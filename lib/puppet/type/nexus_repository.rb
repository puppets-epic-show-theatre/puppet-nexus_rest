Puppet::Type.newtype(:nexus_repository) do
  @doc = "Manages Nexus Repository through a REST API"

  ensurable

  newparam(:name, :namevar => true) do
    desc 'Unique repository identifier; once created cannot be changed unless the repository is destroyed. The Nexus UI will show it as repository id.'
  end

  newproperty(:label) do
    desc 'Human readable label of the repository. The Nexus UI will show it as repository name.'
  end

  newproperty(:type) do
    desc 'Type of this repository. Can be hosted, proxy or virtual; cannot be changed after creation without deleting the repository.'
    newvalues('hosted', 'proxy', 'virtual')
  end

  newproperty(:provider_type) do
    desc 'The content provider of the repository'
    newvalues('maven1', 'maven2', 'nuget', 'site', 'obr')
  end

  newproperty(:policy) do
    desc 'Repositories can store either only release or snapshot artefacts.'
    newvalues('SNAPSHOT', 'RELEASE', 'MIXED')
  end

  newproperty(:exposed, :boolean => true) do
    desc 'Controls if the repository is remotely accessible. Responds to the \'Publish URL\' setting in the UI.'

    munge do |value|
      @resource.munge_boolean(value)
    end
  end

  autorequire(:file) do
    Nexus::Config::CONFIG_FILENAME
  end

  def munge_boolean(value)
    case value
    when true, "true", :true
      :true
    when false, "false", :false
      :false
    else
      fail("munge_boolean only takes booleans")
    end
  end
end
