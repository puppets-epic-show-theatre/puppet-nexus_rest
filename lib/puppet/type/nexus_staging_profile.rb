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
    munge { |value| super(value).to_s.intern }
  end

  newproperty(:searchable, :parent => Puppet::Property::Boolean) do
    desc 'When set to `true`, the repositories created using this profile are indexed and searchable. Setting applies
          only to new repositories.'
    defaultto :true
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
  end

  newproperty(:repository_target) do
    desc 'Name of the repository target that will cause this profile to be selected. This will auto-require the
          referenced `repository_target` resource. You may want to set `implicitly_selectable` to `true` as well.'
  end

  newproperty(:release_repository) do
    desc 'A repository that will be used to release all staged repositories to. This will auto-require the referenced
          `repository` resource.'
  end

  newproperty(:target_groups, :parent => Puppet::Property::List) do
    desc 'A list of repository group names the staging repositories is made available to once it is closed. It is a best
          practice to create a separate group, different from the group typically used for development in order to
          prevent staged artifacts from being leaked to all users. Cannot be empty. All groups will be auto-required.'
  end

  newproperty(:close_notify_emails, :parent => Puppet::Property::List) do
    desc 'A list of email addresses to notify once the staging repository gets closed. Multiple email addresses should
          be specified as an array.'
  end

  newproperty(:close_notify_roles, :parent => Puppet::Property::List) do
    desc 'A list of user roles to notify once the staging repository gets closed. Multiple roles should be specified
          as an array.'
  end

  newproperty(:close_notify_creator, :parent => Puppet::Property::Boolean) do
    desc 'Set to `true` to notify the repository creator (the user who uploaded the repository content) once the staging
          repository gets closed.'
    defaultto :true
    munge { |value| super(value).to_s.intern }
  end

  newproperty(:close_rulesets, :parent => Puppet::Property::List) do
    desc 'The list of `nexus_staging_rulesets` names applied to a staging repository before it can be closed. If the
          staging repository does not pass the rules defined in the specified rulesets, you will not be able to close
          it.'
  end

  newproperty(:promote_notify_emails, :parent => Puppet::Property::List) do
    desc 'A list of email addresses to notify once the staging repository gets promoted. Multiple email addresses should
          be specified as an array.'
  end

  newproperty(:promote_notify_roles, :parent => Puppet::Property::List) do
    desc 'A list of user roles to notify once the staging repository gets promoted. Multiple roles should be specified
          as an array.'
  end

  newproperty(:promote_notify_creator, :parent => Puppet::Property::Boolean) do
    desc 'Set to `true` to notify the repository creator (the user who uploaded the repository content) once the staging
          repository gets promoted.'
    defaultto :true
    munge { |value| super(value).to_s.intern }
  end

  newproperty(:promote_rulesets, :parent => Puppet::Property::List) do
    desc 'The list of `nexus_staging_rulesets` names applied to a staging repository before it can be closed. If the
          staging repository does not pass the rules defined in the specified rulesets, the promotion with fail.'
  end

  newproperty(:drop_notify_emails, :parent => Puppet::Property::List) do
    desc 'A list of email addresses to notify once the staging repository gets dropped. Multiple email addresses should
          be specified as an array.'
  end

  newproperty(:drop_notify_roles, :parent => Puppet::Property::List) do
    desc 'A list of user roles to notify once the staging repository gets dropped. Multiple roles should be specified as
          an array.'
  end

  newproperty(:drop_notify_creator, :parent => Puppet::Property::Boolean) do
    desc 'Set to `true` to notify the repository creator (the user who uploaded the repository content) once the staging
          repository gets dropped.'
    defaultto :true
    munge { |value| super(value).to_s.intern }
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
    self[:close_rulesets].split(',') & self[:promote_rulesets].split(',')
  end
end
