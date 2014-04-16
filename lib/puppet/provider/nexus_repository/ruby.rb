require 'json'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'config.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'rest.rb'))

Puppet::Type.type(:nexus_repository).provide(:ruby) do
  desc "Uses Ruby's rest library"

  def self.instances
    begin
      repositories = Nexus::Rest.get_all('/service/local/repositories')
      repositories['data'].collect do |repository|
        new(
          :name          => repository['id'],
          :label         => repository['name'],
          :ensure        => :present,
          :provider_type => repository['provider']
        )
      end
    rescue => e
      raise Puppet::Error, "Error while retrieving all nexus_repository instances: #{e}"
    end
  end

  def self.prefetch(resources)
    repositories = instances
    resources.keys.each do |name|
      if provider = repositories.find { |repository| repository.name == name }
        resources[name].provider = provider
      end
    end
  end

  def create
    begin
      Nexus::Rest.create('/service/local/repositories', {
        :data => {
          'contentResourceURI'      => Nexus::Config.resolve("/content/repositories/#{resource[:name]}"),
          :id                       => resource[:name],
          :name                     => resource[:label],
          'repoType'                => 'hosted',
          :provider                 => resource[:provider_type],
          'providerRole'            => 'org.sonatype.nexus.proxy.repository.Repository',
          'format'                  => 'maven2',
          'repoPolicy'              => 'SNAPSHOT',

          'writePolicy'             => 'READ_ONLY',
          'browseable'              => true,
          'indexable'               => true,
          'exposed'                 => true,
          'downloadRemoteIndexes'   => false,
          'notFoundCacheTTL'        => 1440,

          'defaultLocalStorageUrl'  => '',
          'overrideLocalStorageUrl' => '',
        }
      })
    rescue Exception => e
      raise Puppet::Error, "Error while creating nexus_repository #{resource[:name]}: #{e}"
    end
  end

  def update
    begin
      Nexus::Rest.update("/service/local/repositories/#{resource[:name]}")
    rescue Exception => e
      raise Puppet::Error, "Error while updating nexus_repository #{resource[:name]}: #{e}"
    end
  end

  def destroy
    begin
      Nexus::Rest.destroy("/service/local/repositories/#{resource[:name]}")
    rescue Exception => e
      raise Puppet::Error, "Error while deleting nexus_repository #{resource[:name]}: #{e}"
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  mk_resource_methods
end