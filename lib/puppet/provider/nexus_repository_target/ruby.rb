require 'json'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'config.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'exception.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'rest.rb'))

Puppet::Type.type(:nexus_repository_target).provide(:ruby) do
  desc "Uses Ruby's rest library"

  confine :feature => :restclient

  def initialize(value={})
    super(value)
    @dirty_flag = false
  end

  def self.instances
    begin
      targets = Nexus::Rest.get_all('/service/local/repo_targets')
      targets['data'].collect do |target|
        new(
          :ensure                  => :present,
          :name                    => target['id'],
          :label                   => target['name'],
          :provider_type           => target.has_key?('contentClass') ? target['contentClass'] : nil,
          :patterns                => target.has_key?('patterns') ? [target['patterns']].flatten : []
        )
      end
    rescue => e
      raise Puppet::Error, "Error while retrieving all nexus_repository_target instances: #{e}"
    end
  end

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
