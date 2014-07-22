module Nexus
  class ScheduledTasks

    class Type
      attr_reader :id, :name

      def initialize(id, name)
        @id   = id
        @name = name
      end
    end

    @@known_types = [
      Type.new('ConfigurationBackupTask', 'Backup all Nexus Configuration Files'),
      Type.new('DownloadIndexesTask', 'Download Indexes'),
      Type.new('DownloadNugetFeedTask', 'Download NuGet Feed'),
      Type.new('DropInactiveRepositoriesTask', 'Drop Inactive Staging Repositories'),
      Type.new('EmptyTrashTask', 'Empty Trash'),
      Type.new('EvictUnusedProxiedItemsTask', 'Evict Unused Proxied Items From Repository Caches'),
      Type.new('ExpireCacheTask', 'Expire Repository Caches'),
      Type.new('UpdateSiteMirrorTask', 'Mirror Eclipse Update Site'),
      Type.new('OptimizeIndexTask', 'Optimize Repository Index'),
      Type.new('PublishIndexesTask', 'Publish Indexes'),
      Type.new('PurgeApiKeysTask', 'Purge Orphaned API Keys'),
      Type.new('RebuildMavenMetadataTask', 'Rebuild Maven Metadata Files'),
      Type.new('RebuildNugetFeedTask', 'Rebuild NuGet Feed'),
      Type.new('P2MetadataGeneratorTask', 'Rebuild P2 metadata'),
      Type.new('P2RepositoryAggregatorTask', 'Rebuild P2 repository'),
      Type.new('ReleaseRemoverTask', 'Remove Releases From Repository'),
      Type.new('SnapshotRemoverTask', 'Remove Snapshots From Repository'),
      Type.new('UnusedSnapshotRemoverTask', 'Remove Unused Snapshots From Repository'),
      Type.new('RepairIndexTask', 'Repair Repositories Index'),
      Type.new('SynchronizeShadowsTask', 'Synchronize Shadow Repository'),
      Type.new('UpdateIndexTask', 'Update Repositories Index'),
      Type.new('GenerateMetadataTask', 'Yum: Generate Metadata')
    ]

    # Returns a type instance identified by the given `type_id`; if the `type_id` is not known, a new type instance is
    # created on the fly using the the `type_id` as `name`.
    #
    def self.find_type_by_id(type_id)
      needle = type_id.to_s
      known_type = @@known_types.find { |type| type.id == needle }
      known_type ? known_type : Type.new(needle, needle)
    end

    # Returns a type instance identified by the given `type_name`; if the `type_name` is not known, a new type instance
    # is created on the fly using the `type_name` as `id`. If there are multipe types with the same name, only the
    # first is considered.
    #
    def self.find_type_by_name(type_name)
      needle = type_name.to_s
      known_type = @@known_types.find { |type| type.name == needle }
      known_type ? known_type : Type.new(needle, needle)
    end
  end
end
