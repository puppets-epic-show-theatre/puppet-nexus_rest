require 'json'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'config.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'exception.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'rest.rb'))

Puppet::Type.type(:nexus_access_privilege).provide(:ruby) do
  desc "Uses Ruby's rest library"

  BASENAME_DELIMITER = ' - ('

  def initialize(value={})
    super(value)
    @dirty_flag = false
  end


    #{
    #  "id": "30e78e31cda726",
    #  "resourceURI": "http://nexus-atlassian-misc.buildeng.atlassian.com:8081/service/local/privileges/30e78e31cda726",
    #  "name": "atlassian-license-rw - (delete)",
    #  "description": "atlassian-license-rw",
    #  "type": "target",
    #  "userManaged": true,
    #  "properties": [
    #    {
    #      "key": "repositoryGroupId",
    #      "value": ""
    #    },
    #    {
    #      "key": "method",
    #      "value": "delete,read"
    #    },
    #    {
    #      "key": "repositoryId",
    #      "value": "atlassian-license"
    #    },
    #    {
    #      "key": "repositoryTargetId",
    #      "value": "any"
    #    }
    #  ]
    #},


  def self.instances
    begin
      privileges = Nexus::Rest.get_all('/service/local/privileges')
      targets['data'].collect do |privilege|
        next if !privilege['userManaged']

        properties = Hash[privilege['properties'].collect { |key_value| [key_value['key'], key_value['value']] }]

        new(
          :ensure                  => :present,
          :id                      => privilege['id'],
          :name                    => privilege['name'].split(BASENAME_DELIMITER),
          :description             => privilege['description'],
          :methods                 => properties.has_key?('method') ? properties['method'] : nil,
          :repository_target       => properties.has_key?('repositoryTargetId') ? properties['repositoryTargetId'] : nil,
          :repository              => properties.has_key?('repositoryId') ? properties['repositoryId'] : '',
          :repository_group        => properties.has_key?('repositoryGroupId') ? properties['repositoryGroupId'] : '',
        )
      end.compact
    rescue => e
      raise Puppet::Error, "Error while retrieving all nexus_access_privilege instances: #{e}"
    end
  end

  #######################
  #######################
  #######################
  #######################
  #WIP WIP WIP WIP WIP
  #######################
  #######################
  #######################
  #######################

  def self.prefetch(resources)
    targets = instances
    resources.keys.each do |name|
      if provider = targets.find { |target| target.name == name }
        resources[name].provider = provider
      end
    end
  end

  def create
    begin
      Nexus::Rest.create('/service/local/repo_targets', map_resource_to_data)
    rescue Exception => e
      raise Puppet::Error, "Error while creating nexus_repository_target #{resource[:name]}: #{e}"
    end
  end

  def flush
    if @dirty_flag
      begin
        Nexus::Rest.update("/service/local/repo_targets/#{resource[:name]}", map_resource_to_data)
      rescue Exception => e
        raise Puppet::Error, "Error while updating nexus_repository_target #{resource[:name]}: #{e}"
      end
      @property_hash = resource.to_hash
    end
  end

  def destroy
    begin
      Nexus::Rest.destroy("/service/local/repo_targets/#{resource[:name]}")
    rescue Exception => e
      raise Puppet::Error, "Error while deleting nexus_repository_target #{resource[:name]}: #{e}"
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  # Returns the resource in a representation as expected by Nexus:
  #
  # {
  #   :data => {
  #              :id   => <resource name>
  #              :name => <resource label>
  #              ...
  #            }
  # }
  def map_resource_to_data
    data = {
      :id                      => resource[:name],
      :name                    => resource[:label],
      :contentClass            => resource[:provider_type].to_s,
      :patterns                => [resource[:patterns]].flatten
    }
    {:data => data}
  end

  mk_resource_methods

  def label=(value)
    @dirty_flag = true
  end

  def provider_type=(value)
    @dirty_flag = true
  end

  def patterns=(value)
    @dirty_flag = true
  end

end

