module Nexus
  class StagingRuleset

    class Type
      attr_reader :id, :name

      def initialize(id, name)
        @id   = id
        @name = name
      end
    end

    @@known_types = [
      Type.new('uniq-staging', 'Artifact Uniqueness Validation'),
      Type.new('checksum-staging', 'Checksum Validation'),
      Type.new('javadoc-staging', 'Javadoc Validation'),
      Type.new('no-promotion-allowed-staging', 'No promote action allowed'),
      Type.new('no-release-allowed-staging', 'No release action allowed'),
      Type.new('no-system-scope-in-pom-staging', 'POM Validation'),
      Type.new('no-release-repo-staging', 'POM must not contain \'system\' scoped dependencies'),
      Type.new('pom-staging', 'POM must not contain release repository'),
      Type.new('profile-target-matching-staging', 'Profile target matcher'),
      Type.new('signature-staging', 'Signature Validation'),
      Type.new('sources-staging', 'Sources Validation'),
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
