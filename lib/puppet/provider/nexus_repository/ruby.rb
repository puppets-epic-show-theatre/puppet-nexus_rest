require 'json'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'config.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'exception.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'rest.rb'))

Puppet::Type.type(:nexus_repository).provide(:ruby) do
  desc "Uses Ruby's rest library"

  WRITE_ONCE_ERROR_MESSAGE = "%s is write-once only and cannot be changed without force."
  PROVIDER_TYPE_MAPPING = {
    'maven1'    => {
      :provider     => 'maven1',
      :providerRole => 'org.sonatype.nexus.proxy.repository.Repository',
      :format       => 'maven1',
    },
    'maven2'    => {
      :provider     => 'maven2',
      :providerRole => 'org.sonatype.nexus.proxy.repository.Repository',
      :format       => 'maven2',
    },
    'obr' => {
      :provider     => 'obr-proxy',
      :providerRole => 'org.sonatype.nexus.proxy.repository.Repository',
      :format       => 'obr',
    },
    'nuget'     => {
      :provider     => 'nuget-proxy',
      :providerRole => 'org.sonatype.nexus.proxy.repository.Repository',
      :format       => 'nuget',
    },
    'site'      => {
      :provider     => 'site',
      :providerRole => 'org.sonatype.nexus.proxy.repository.WebSiteRepository',
      :format       => 'site',
    },
  }

  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def self.instances
    begin
      repositories = Nexus::Rest.get_all_plus_n('/service/local/repositories')
      repositories['data'].collect do |repository|
        new(
          :ensure                  => :present,
          :name                    => repository['id'],
          :label                   => repository['name'],
          :provider_type           => repository['format'], # TODO using the format because it maps 1:1 to the provider_type
          :type                    => repository['repoType'],
          :policy                  => repository['repoPolicy'],
          :exposed                 => repository['exposed'].to_s,
          :write_policy            => repository.has_key?('writePolicy') ? repository['writePolicy'].to_sym : nil,
          :browseable              => repository['browseable'].to_s,
          :indexable               => repository['indexable'].to_s,
          :not_found_cache_ttl     => repository.has_key?('notFoundCacheTTL') ? Integer(repository['notFoundCacheTTL']) : nil,
          :local_storage_url       => repository.has_key?('overrideLocalStorageUrl') ? repository['overrideLocalStorageUrl'] : nil,
          :download_remote_indexes => repository.has_key?('downloadRemoteIndexes') ? repository['downloadRemoteIndexes'].to_s : :false
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
      Nexus::Rest.create('/service/local/repositories', map_resource_to_data)
    rescue Exception => e
      raise Puppet::Error, "Error while creating nexus_repository #{resource[:name]}: #{e}"
    end
  end

  def flush
    if @property_flush
      data = {}
      data[:repoPolicy] = resource[:policy].to_s if @property_flush[:policy]
      data[:exposed] = resource[:exposed] == :true if @property_flush[:exposed]
      data[:writePolicy] = resource[:write_policy] if @property_flush[:write_policy]
      data[:browseable] = resource[:browseable] == :true if @property_flush[:browseable]
      data[:indexable] = resource[:indexable] == :true if @property_flush[:indexable]
      data[:notFoundCacheTTL] = resource[:not_found_cache_ttl] if @property_flush[:not_found_cache_ttl]
      data[:downloadRemoteIndexes] = resource[:download_remote_indexes] == :true if @property_flush[:download_remote_indexes]
      data[:overrideLocalStorageUrl] = resource[:local_storage_url] if @property_flush[:local_storage_url] and !resource[:local_storage_url].nil?
      # required values
      data[:id] = resource[:name]
      data[:repoType] = resource[:type]
      data[:repoPolicy] = resource[:policy].to_s
      begin
        Nexus::Rest.update("/service/local/repositories/#{resource[:name]}", {:data => data})
      rescue Exception => e
        raise Puppet::Error, "Error while updating nexus_repository #{resource[:name]}: #{e}"
      end
      @property_hash = resource.to_hash
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
    content_type_details = PROVIDER_TYPE_MAPPING[resource[:provider_type].to_s] or raise Puppet::Error, "Nexus_repository[#{resource[:name]}]: unable to find a suitable mapping for type #{resource[:provider_type]}"
    data = {
      :id                      => resource[:name],
      :name                    => resource[:label],
      :repoType                => resource[:type].to_s,
      :provider                => content_type_details[:provider],
      :providerRole            => content_type_details[:providerRole],
      :format                  => content_type_details[:format],
      :repoPolicy              => resource[:policy].to_s,
      :exposed                 => resource[:exposed] == :true,

      :writePolicy             => resource[:write_policy].to_s,
      :browseable              => resource[:browseable] == :true,
      :indexable               => resource[:indexable] == :true,
      :notFoundCacheTTL        => resource[:not_found_cache_ttl],

      :downloadRemoteIndexes   => resource[:download_remote_indexes] == :true,
    }
    data[:overrideLocalStorageUrl] = resource[:local_storage_url] unless resource[:local_storage_url].nil?
    {:data => data}
  end

  mk_resource_methods

  def type=(value)
    raise Puppet::Error, WRITE_ONCE_ERROR_MESSAGE % 'type'
  end

  def provider_type=(value)
    raise Puppet::Error, WRITE_ONCE_ERROR_MESSAGE % 'provider_type'
  end

  def policy=(value)
    @property_flush[:policy] = true
  end

  def exposed=(value)
    @property_flush[:exposed] = true
  end

  def write_policy=(value)
    raise Puppet::Error, "Write policy cannot be changed." unless resource[:type] == :hosted
    @property_flush[:write_policy] = true
  end

  def browseable=(value)
    @property_flush[:browseable] = true
  end

  def indexable=(value)
    @property_flush[:indexable] = true
  end

  def not_found_cache_ttl=(value)
    @property_flush[:not_found_cache_ttl] = true
  end

  def download_remote_indexes=(value)
    @property_flush[:download_remote_indexes] = true
  end

  def local_storage_url=(value)
    @property_flush[:local_storage_url] = true
  end
end