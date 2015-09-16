require 'json'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'config.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'exception.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'rest.rb'))

Puppet::Type.type(:nexus_repository_route).provide(:ruby) do
  desc "Uses Ruby's rest library"

  confine :feature => :restclient

  def initialize(value={})
    super(value)
    @dirty_flag = false
  end

  def self.instances
    begin
      order = -1

      routes = Nexus::Rest.get_all('/service/local/repo_routes')

      if !routes.empty?
        #obtain complete data for each route
        routes['data'] = routes['data'].collect { |route|
          #the use "resourceURI" path to get the complete route
          route = Nexus::Rest.get_all(URI(route['resourceURI']).path)['data']
        }.flatten

        #sorting by id to give some sense of stability
        [routes['data']].flatten.sort_by { |route| route['id'] }.collect { |route|
          order += 1

          repositories = route['repositories'].collect { |repository| repository['id'] }

          new(
            :name                    => "#{order}",
            :ensure                  => :present,
            :id                      => route['id'],
            :url_pattern             => route['pattern'],
            :rule_type               => route.has_key?('ruleType') ? route['ruleType'].to_s.to_sym : nil,
            :repository_group        => route['groupId'],
            :repositories            => repositories.join(',')
          )
        }
      else
        []
      end

    rescue => e
      raise Puppet::Error, "Error while retrieving all nexus_repository_route instances: #{e}"
    end
  end

  def self.prefetch(resources)
    routes = instances
    resources.keys.each do |name|
      if provider = routes.find { |route| route.name == name }
        resources[name].provider = provider
      end
    end
  end

  def create
    begin
      Nexus::Rest.create('/service/local/repo_routes', map_resource_to_data)
    rescue Exception => e
      raise Puppet::Error, "Error while creating nexus_repository_route #{resource[:name]}: #{e}"
    end
  end

  def flush
    if @dirty_flag
      begin
        Nexus::Rest.update("/service/local/repo_routes/#{@property_hash[:id]}", map_resource_to_data)
        @property_hash = resource.to_hash
      rescue Exception => e
        raise Puppet::Error, "Error while updating nexus_repository_route #{resource[:name]}: #{e}"
      end
    end
  end

  def destroy
    begin
      Nexus::Rest.destroy("/service/local/repo_routes/#{@property_hash[:id]}")
    rescue Exception => e
      raise Puppet::Error, "Error while deleting nexus_repository_route #{resource[:name]}: #{e}"
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
      :id              => @property_hash[:id],
      :pattern         => resource[:url_pattern],
      :ruleType        => resource[:rule_type],
      :groupId         => resource[:repository_group],
      :repositories    => resource[:repositories].split(',').collect { |repository| {'id' => repository} }
    }
    {:data => data}
  end

  mk_resource_methods

  def id=(value)
    @dirty_flag = true
  end

  def url_pattern=(value)
    @dirty_flag = true
  end

  def rule_type=(value)
    @dirty_flag = true
  end

  def repositories=(value)
    @dirty_flag = true
  end

  def repository_group=(value)
    @dirty_flag = true
  end

end
