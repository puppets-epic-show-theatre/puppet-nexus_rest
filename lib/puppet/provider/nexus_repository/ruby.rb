require 'json'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'nexus_rest.rb'))

Puppet::Type.type(:nexus_repository).provide(:ruby) do
    desc "Uses Ruby's rest library"

    def self.instances
      repositories = Nexus::Rest.get_all('/service/local/repositories')
      return repositories['data'].collect do |repository|
        name = repository['id']
        new(:name => name, :ensure => :present)
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
        Nexus::Config.configure { |base_url|
          Nexus::Rest.create('/service/local/repositories', {
          'data' => {
            'contentResourceURI'      => "#{base_url}/content/repositories/#{resource[:name]}",
            'id'                      => resource[:name],
            'name'                    => resource[:name],
            'repoType'                => 'hosted',
            'provider'                => 'maven2',
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
      }
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
end