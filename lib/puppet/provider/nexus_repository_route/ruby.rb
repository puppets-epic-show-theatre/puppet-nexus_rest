require 'json'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'config.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'exception.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'rest.rb'))

Puppet::Type.type(:nexus_repository_route).provide(:ruby) do
  desc "Uses Ruby's rest library"

  def initialize(value={})
    super(value)
    @dirty_flag = false
  end

  def self.instances
    begin
      order = 0

      routes = Nexus::Rest.get_all('/service/local/repo_routes')
      routes['data'].collect do |route|

        repositories = route['repositories'].collect { |repository| repository['id'] }

        new(
          #:name                    => "nexus_repository_route_#{order}",
          :ensure                  => :present,
          :id                      => route['id'],
          :order                   => order,
          :url_pattern             => route['url_pattern'],
          :rule_type               => route.has_key?('rule_type') ? route['rule_type'].to_s.to_sym : nil,
          :repository_group        => route['groupId'],
          :repositories            => repositories.collect
        )

        order += 1
      end
    rescue => e
      raise Puppet::Error, "Error while retrieving all nexus_repository_route instances: #{e}"
    end
  end

  def self.prefetch(resources)
    groups = instances
    resources.keys.each do |name|
      if provider = groups.find { |group| group.order == resources[name].order }
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
        Nexus::Rest.update("/service/local/repo_routes/#{resource[:name]}", map_resource_to_data)
      rescue Exception => e
        raise Puppet::Error, "Error while updating nexus_repository_route #{resource[:name]}: #{e}"
      end
      @property_hash = resource.to_hash
    end
  end

  def destroy
    begin
      Nexus::Rest.destroy("/service/local/repo_routes/#{resource[:name]}")
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
      :url_pattern             => resource[:url_pattern],
      :rule_type               => resource[:rule_type],
      :repository_group        => resource[:repository_group],
      :repositories            => resource[:repositories].collect { |repository| {'id' => repository} }
    }
    {:data => data}
  end

  mk_resource_methods

  def url_pattern=(value)
    @dirty_flag = true
  end

  def rule_type=(value)
    @dirty_flag = true
  end

  def repository_group=(value)
    @dirty_flag = true
  end

  def repository_group=(value)
    @dirty_flag = true
  end

end
