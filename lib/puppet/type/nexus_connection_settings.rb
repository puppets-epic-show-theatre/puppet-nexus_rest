Puppet::Type.newtype(:nexus_connection_settings) do
  @doc = 'Manage the global connection settings.'

  newparam(:name, :namevar => true) do
    desc 'Name of the configuration (i.e. current).'
  end

  newproperty(:timeout) do
    desc 'Time in seconds Nexus will wait for a successful connection before retrying.'
    defaultto 10
    validate do |value|
      raise ArgumentError, "Timeout must be a non-negative integer, got #{value}" unless value.to_s =~ /\d+/
      raise ArgumentError, "Timeout must bigger than or equal to zero" unless value.to_i >= 0
    end
    munge { |value| Integer(value) }
  end

  newproperty(:retries) do
    desc 'Number of connection attempts before giving up.'
    defaultto 3
    validate do |value|
      raise ArgumentError, "Retries must be a non-negative integer, got #{value}" unless value.to_s =~ /\d+/
      raise ArgumentError, "Retries must bigger than or equal to zero" unless value.to_i >= 0
    end
    munge { |value| Integer(value) }
  end

  newproperty(:user_agent_fragment) do
    desc 'A custom fragment to add to the `user-agent` string used in HTTP requests.'
    defaultto ''
  end

  newproperty(:query_string) do
    desc 'Additional parameters sent along with the HTTP request. They are appended to the url along with a `?`. E.g.
      `foo=bar&foo2=bar2` becomes `http://myurl?foo=bar&foo2=bar2`.'
    defaultto ''
  end

  autorequire(:file) do
    Nexus::Config::file_path
  end
end
