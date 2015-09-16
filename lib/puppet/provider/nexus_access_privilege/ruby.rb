require 'json'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'config.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'exception.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'rest.rb'))

Puppet::Type.type(:nexus_access_privilege).provide(:ruby) do
  desc "Uses Ruby's rest library"

  confine :feature => :restclient

  BASENAME_DELIMITER = ' - ('

  def initialize(value={})
    super(value)
    @update_required = false
  end

  def self.instances
    begin
      privilege_bucket = {}
      privileges = Nexus::Rest.get_all('/service/local/privileges')['data']

      privileges.collect do |privilege|
        next if !privilege['userManaged']

        privilege_name = privilege['name'].split(BASENAME_DELIMITER)[0]

        privilege_name = "#{privilege_name}-#{privilege['id']}" if privilege_bucket.has_key?(privilege_name)
        privilege_bucket[privilege_name] = true

        properties = Hash[privilege['properties'].collect { |key_value| [key_value['key'], key_value['value']] }]

        new(
          :ensure                  => :present,
          :name                    => privilege_name,
          :id                      => privilege['id'],
          :description             => privilege['description'],
          :methods                 => properties.has_key?('method') ? properties['method'].split(',') : nil,
          :repository_target       => properties.has_key?('repositoryTargetId') ? properties['repositoryTargetId'] : nil,
          :repository              => properties.has_key?('repositoryId') ? properties['repositoryId'] : '',
          :repository_group        => properties.has_key?('repositoryGroupId') ? properties['repositoryGroupId'] : ''
        )
      end.compact
    rescue => e
      raise Puppet::Error, "Error while retrieving all nexus_access_privilege instances: #{e}"
    end
  end

  def self.prefetch(resources)
    privileges = instances
    resources.keys.each do |name|
      if provider = privileges.find { |target| target.name == name }
        resources[name].provider = provider
      end
    end
  end

  def create
    begin
      Nexus::Rest.create('/service/local/privileges_target', map_resource_to_data)
    rescue Exception => e
      raise Puppet::Error, "Error while creating nexus_access_privilege #{resource[:name]}: #{e}"
    end
  end

  def flush
    if @update_required
      begin
        # cannot update, must recreate
        Nexus::Rest.destroy("/service/local/privileges/#{@property_hash[:id]}")
        Nexus::Rest.create("/service/local/privileges_target", map_resource_to_data)

        # created privilege will have a new random id
        resource[:id] = self.class.privilege_id_from_name(resource[:name])
      rescue Exception => e
        raise Puppet::Error, "Error while updating nexus_access_privilege #{resource[:name]}: #{e}"
      end
      @property_hash = resource.to_hash
    end
  end

  def destroy
    begin
      Nexus::Rest.destroy("/service/local/privileges/#{@property_hash[:id]}")
    rescue Exception => e
      raise Puppet::Error, "Error while deleting nexus_access_privilege #{resource[:name]}: #{e}"
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  # Returns the resource in a representation as expected by Nexus:
  #
  # {
  #   :data => {
  #              :name        => <resource name>
  #              :description => <resource description>
  #              ...
  #            }
  # }
  def map_resource_to_data
    data = {
      :name                    => resource[:name].to_s,
      :description             => resource[:description].to_s,
      :type                    => 'target',
      :repositoryTargetId      => resource[:repository_target].to_s,
      :repositoryId            => resource[:repository].to_s,
      :repositoryGroupId       => resource[:repository_group].to_s,
      :method                  => [ resource[:methods].kind_of?(Array) ? resource[:methods].join(',') : resource[:methods].to_s ]
    }
    {:data => data}
  end

  def self.privilege_id_from_name(name)
    # since we can't set the id, we can use this method to fetch it
    privilege = instances.select {|privilege| privilege.name == name}
    raise Puppet::Error, "Error while looking up id of nexus_access_privilege '#{name}'" if privilege.count != 1
    privilege[0].id
  end

  mk_resource_methods

  def mark_config_dirty
    @update_required = true
  end

  def description=(value)
    mark_config_dirty
  end

  def repository_target=(value)
    mark_config_dirty
  end

  def repository=(value)
    mark_config_dirty
  end

  def repository_group=(value)
    mark_config_dirty
  end

  def methods=(value)
    mark_config_dirty
  end

end
