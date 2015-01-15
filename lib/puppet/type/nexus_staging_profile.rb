require 'puppet/property/boolean'
require 'puppet/property/list'

Puppet::Type.newtype(:nexus_staging_profile) do
  @doc = 'Nexus staging profiles provide a staging repository where artifacts can be kept until they are ready to be
          released.'

  ensurable

  newparam(:name, :namevar => true) do
    desc 'The name of the staging profile.'
  end

  newparam(:id) do
    desc 'A read-only parameter set by the nexus_staging_profile resource.'
  end

  newproperty(:implicitly_selectable, :parent => Puppet::Property::Boolean) do
    desc 'When set to `true`, the profile will be included as a possible match using user agent, IP address, username
          and repository target if the profile ID is not specified explicitly. Setting to `false` means this profile
          will only be selected when identified by the profile ID. The Nexus UI will show it as `Profile Selection
          Strategy`.'
    defaultto :true
    validate do |value|
      raise ArgumentError, 'must be :true or :false, but not an empty string' if value.to_s.empty?
    end
    munge { |value| super(value).to_s.intern }
  end

  newproperty(:searchable, :parent => Puppet::Property::Boolean) do
    desc 'When set to `true`, the repositories created using this profile are indexed and searchable. Setting applies
          only to new repositories.'
    defaultto :true
    validate do |value|
      raise ArgumentError, 'must be :true or :false, but not an empty string' if value.to_s.empty?
    end
    munge { |value| super(value).to_s.intern }
  end

  newproperty(:staging_mode) do
    desc 'The source(s) this profile will accept artifacts from, either from the staging deploy URL (`deploy`), or
          staging upload via the UI (`upload`), or both (`both`).'
    defaultto :both
    newvalues(:deploy, :upload, :both)
  end

  newproperty(:staging_template) do
    desc 'Template used for creating staging repositories.'
    defaultto 'default_hosted_release'
    validate do |value|
      raise ArgumentError, 'must be a non-empty string' if value.to_s.empty?
    end
  end

  newproperty(:repository_type) do
    desc 'The type of the generated staging repositories (e.g. `maven1` or `maven2`). The Nexus UI will show it as
          `Content Type`.'
    defaultto :maven2
    validate do |value|
      raise ArgumentError, 'must be a non-empty string' if value.to_s.empty?
    end
  end

  newproperty(:repository_target) do
    desc 'Name of the repository target that will cause this profile to be selected. This will auto-require the
          referenced `repository_target` resource. You may want to set `implicitly_selectable` to `true` as well.'
    validate do |value|
      raise ArgumentError, 'must be a non-empty string' if value.to_s.empty?
    end
  end

  newproperty(:release_repository) do
    desc 'A repository that will be used to release all staged repositories to. This will auto-require the referenced
          `repository` resource.'
    validate do |value|
      raise ArgumentError, 'must be a non-empty string' if value.to_s.empty?
    end
  end

  newproperty(:target_groups, :parent => Puppet::Property::List) do
    desc 'A list of repository group names the staging repositories is made available to once it is closed. It is a best
          practice to create a separate group, different from the group typically used for development in order to
          prevent staged artifacts from being leaked to all users. Cannot be empty. All groups will be auto-required.'
    validate do |value|
      raise ArgumentError, 'Target groups must not be empty' if value.to_s.empty?
      raise ArgumentError, 'Multiple target groups must be provided as an array, not a comma-separated list.' if value.to_s.include?(',')
    end
    def membership
      :inclusive_membership
    end
  end

  newproperty(:close_notify_emails, :parent => Puppet::Property::List) do
    desc 'A list of email addresses to notify once the staging repository gets closed. Multiple email addresses should
          be specified as an array.'
    defaultto []
    validate do |value|
      unless value.empty?
        raise ArgumentError, "Invalid email address '#{value}'." if value !~ /@/
        raise ArgumentError, 'Multiple email addresses must be provided as an array, not a comma-separated list.' if value.include?(',')
      end
    end
    def membership
      :inclusive_membership
    end
  end

  newproperty(:close_notify_roles, :parent => Puppet::Property::List) do
    desc 'A list of user roles to notify once the staging repository gets closed. Multiple roles should be specified
          as an array.'
    defaultto []
    validate do |value|
      unless value.empty?
        raise ArgumentError, 'Multiple roles must be provided as an array, not a comma-separated list.' if value.include?(',')
      end
    end
    def membership
      :inclusive_membership
    end
  end

  newproperty(:close_notify_creator, :parent => Puppet::Property::Boolean) do
    desc 'Set to `true` to notify the repository creator (the user who uploaded the repository content) once the staging
          repository gets closed.'
    defaultto :true
    validate do |value|
      raise ArgumentError, 'must be :true or :false, but not an empty string' if value.to_s.empty?
    end
    munge { |value| super(value).to_s.intern }
  end

  newproperty(:close_rulesets, :parent => Puppet::Property::List) do
    desc 'The list of `nexus_staging_rulesets` names applied to a staging repository before it can be closed. If the
          staging repository does not pass the rules defined in the specified rulesets, you will not be able to close
          it.'
    defaultto []
    validate do |value|
      unless value.empty?
        raise ArgumentError, 'Multiple rulesets must be provided as an array, not a comma-separated list.' if value.include?(',')
      end
    end
    def membership
      :inclusive_membership
    end
  end

  newproperty(:promote_notify_emails, :parent => Puppet::Property::List) do
    desc 'A list of email addresses to notify once the staging repository gets promoted. Multiple email addresses should
          be specified as an array.'
    defaultto []
    validate do |value|
      unless value.empty?
        raise ArgumentError, "Invalid email address '#{value}'." if value !~ /@/
        raise ArgumentError, 'Multiple email addresses must be provided as an array, not a comma-separated list.' if value.include?(',')
      end
    end
    def membership
      :inclusive_membership
    end
  end

  newproperty(:promote_notify_roles, :parent => Puppet::Property::List) do
    desc 'A list of user roles to notify once the staging repository gets promoted. Multiple roles should be specified
          as an array.'
    defaultto []
    validate do |value|
      unless value.empty?
        raise ArgumentError, 'Multiple roles must be provided as an array, not a comma-separated list.' if value.include?(',')
      end
    end
    def membership
      :inclusive_membership
    end
  end

  newproperty(:promote_notify_creator, :parent => Puppet::Property::Boolean) do
    desc 'Set to `true` to notify the repository creator (the user who uploaded the repository content) once the staging
          repository gets promoted.'
    defaultto :true
    validate do |value|
      raise ArgumentError, 'must be :true or :false, but not an empty string' if value.to_s.empty?
    end
    munge { |value| super(value).to_s.intern }
  end

  newproperty(:promote_rulesets, :parent => Puppet::Property::List) do
    desc 'The list of `nexus_staging_rulesets` names applied to a staging repository before it can be closed. If the
          staging repository does not pass the rules defined in the specified rulesets, the promotion with fail.'
    defaultto []
    validate do |value|
      unless value.empty?
        raise ArgumentError, 'Multiple rulesets must be provided as an array, not a comma-separated list.' if value.include?(',')
      end
    end
    def membership
      :inclusive_membership
    end
  end

  newproperty(:drop_notify_emails, :parent => Puppet::Property::List) do
    desc 'A list of email addresses to notify once the staging repository gets dropped. Multiple email addresses should
          be specified as an array.'
    defaultto []
    validate do |value|
      unless value.empty?
        raise ArgumentError, "Invalid email address '#{value}'." if value !~ /@/
        raise ArgumentError, 'Multiple email addresses must be provided as an array, not a comma-separated list.' if value.include?(',')
      end
    end
    def membership
      :inclusive_membership
    end
  end

  newproperty(:drop_notify_roles, :parent => Puppet::Property::List) do
    desc 'A list of user roles to notify once the staging repository gets dropped. Multiple roles should be specified as
          an array.'
    defaultto []
    validate do |value|
      unless value.empty?
        raise ArgumentError, 'Multiple roles must be provided as an array, not a comma-separated list.' if value.include?(',')
      end
    end
    def membership
      :inclusive_membership
    end
  end

  newproperty(:drop_notify_creator, :parent => Puppet::Property::Boolean) do
    desc 'Set to `true` to notify the repository creator (the user who uploaded the repository content) once the staging
          repository gets dropped.'
    defaultto :true
    validate do |value|
      raise ArgumentError, 'must be :true or :false, but not an empty string' if value.to_s.empty?
    end
    munge { |value| super(value).to_s.intern }
  end

  validate do
    if self[:ensure] == :present
      raise ArgumentError, 'repository_target is a mandatory property' if self[:repository_target].nil?
      raise ArgumentError, 'release_repository is a mandatory property' if self[:release_repository].nil?
      raise ArgumentError, 'target_groups is a mandatory property' if self[:target_groups].nil?
      raise ArgumentError, 'target_groups must not be empty' if self[:target_groups].to_s.empty?
    end
  end

  newparam(:inclusive_membership) do
    desc 'The list is considered a complete lists as opposed to minimum lists.'
    newvalues(:inclusive)
    defaultto :inclusive
  end

  autorequire(:file) do
    Nexus::Config::file_path
  end

  autorequire(:nexus_repository_target) do
    self[:repository_target]
  end

  autorequire(:nexus_repository) do
    self[:release_repository]
  end

  autorequire(:nexus_repository_group) do
    self[:target_groups].split(',')
  end

  autorequire(:nexus_staging_ruleset) do
    self[:close_rulesets].split(',') + self[:promote_rulesets].split(',')
  end
end
