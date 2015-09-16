require 'json'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'config.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'exception.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'rest.rb'))

Puppet::Type.type(:nexus_repository_group).provide(:ruby) do
  desc "Uses Ruby's rest library"

  confine :feature => :restclient

  FORMAT_TO_PROVIDER_MAPPING = {
    :maven1    => 'maven1',
    :maven2    => 'maven2',
    :obr       => 'obr-group',
    :nuget     => 'nuget-group',
    :npm       => 'npm-group',
    :rubygems  => 'rubygems-group',
  }

  def initialize(value={})
    super(value)
    @dirty_flag = false
  end

  def self.instances
    begin
      groups = Nexus::Rest.get_all_plus_n('/service/local/repo_groups')
      groups['data'].collect do |group|

        #simplify data schema into an array of ids, rather than an array of objects with id properties
        repositories = group['repositories'].collect { |repository| repository['id'] }

        new(
          :ensure                  => :present,
          :name                    => group['id'],
          :label                   => group['name'],
          :provider_type           => group.has_key?('format') ? group['format'].to_sym : nil,
          :exposed                 => group.has_key?('exposed') ? group['exposed'].to_s.to_sym : nil,
          :repositories            => repositories
        )
      end
    rescue => e
      raise Puppet::Error, "Error while retrieving all nexus_repository_group instances: #{e}"
    end
  end

  def self.prefetch(resources)
    groups = instances
    resources.keys.each do |name|
      if provider = groups.find { |group| group.name == name }
        resources[name].provider = provider
      end
    end
  end

  def create
    begin
      Nexus::Rest.create('/service/local/repo_groups', map_resource_to_data)
    rescue Exception => e
      raise Puppet::Error, "Error while creating nexus_repository_group #{resource[:name]}: #{e}"
    end
  end

  def flush
    if @dirty_flag
      begin
        Nexus::Rest.update("/service/local/repo_groups/#{resource[:name]}", map_resource_to_data)
      rescue Exception => e
        raise Puppet::Error, "Error while updating nexus_repository_group #{resource[:name]}: #{e}"
      end
      @property_hash = resource.to_hash
    end
  end

  def destroy
    begin
      Nexus::Rest.destroy("/service/local/repo_groups/#{resource[:name]}")
    rescue Exception => e
      raise Puppet::Error, "Error while deleting nexus_repository_group #{resource[:name]}: #{e}"
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
      :format                  => resource[:provider_type],
      :provider                => FORMAT_TO_PROVIDER_MAPPING[resource[:provider_type]],
      :exposed                 => resource[:exposed] == :true,

      :repositories            => resource[:repositories].collect { |repository| {'id' => repository} }
    }
    {:data => data}
  end

  mk_resource_methods

  def provider_type=(value)
    raise Puppet::Error, WRITE_ONCE_ERROR_MESSAGE % 'provider_type'
  end

  def label=(value)
    @dirty_flag = true
  end

  def exposed=(value)
    @dirty_flag = true
  end

  def repositories=(value)
    @dirty_flag = true
  end

end
