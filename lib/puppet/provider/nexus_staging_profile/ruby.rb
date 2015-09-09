require 'json'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'config.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'exception.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'rest.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'util.rb'))

Puppet::Type.type(:nexus_staging_profile).provide(:ruby) do

  confine :feature => :restclient

  def initialize(value={})
    super(value)
    @update_required = false
  end

  def self.instances
    begin
      known_rulesets = get_known_rulesets
      staging_profiles = Nexus::Rest.get_all('/service/local/staging/profiles')['data']
      staging_profiles.collect { |staging_profile| new(map_data_to_resource(staging_profile, known_rulesets)) }
    rescue => e
      raise Puppet::Error, "Error while retrieving all nexus_staging_profile instances: #{e}"
    end
  end

  # Returns a hash of known staging rulesets:
  #
  # {
  #   'rulesetX_id' => 'rulesetX_name',
  #   'rulesetY_id' => 'rulesetY_name',
  # }
  #
  def self.get_known_rulesets
    Nexus::Rest.get_all('/service/local/staging/rule_sets')['data'].inject({}) do |processed_rulesets, ruleset|
      processed_rulesets.merge({ruleset['id'] => ruleset['name']})
    end
  end

  # Map the received json hash to a Puppet resource hash which is used to create a new resource instance.
  #
  # {
  #    ...
  #    'id': ...
  #    'name': ...
  #    'description': ...
  #    'rules': [
  #      {
  #         ...
  #      }
  #    ]
  # }
  #
  # returns: A map of data representing the Puppet resource state.
  # {
  #    :puppet_attribute_1 => ...,
  #    :puppet_attribute_2 => ...,
  #    :puppet_attribute_3 => ...,
  # }
  #
  def self.map_data_to_resource(staging_profile, known_rulesets)
    {
        :ensure                 => :present,
        :id                     => staging_profile['id'],
        :name                   => staging_profile['name'],
        :implicitly_selectable  => (!staging_profile.fetch('autoStagingDisabled', false)).to_s.intern,
        :searchable             => Nexus::Util.a_boolean_or_absent(staging_profile['repositoriesSearchable']),
        :staging_mode           => staging_profile.fetch('mode', :absent).to_s.downcase.intern,
        :staging_template       => staging_profile.fetch('repositoryTemplateId', :absent),
        :repository_type        => staging_profile.fetch('repositoryType', :absent),
        :repository_target      => staging_profile.fetch('repositoryTargetId', :absent),
        :release_repository     => staging_profile.fetch('promotionTargetRepository', :absent),
        :target_groups          => Nexus::Util.a_list_or_absent(staging_profile['targetGroups']),

        # emails come in a comma-separate strings which is the expected format of the list property - but only if there
        # is an email set at all, otherwise it is omitted
        :close_notify_emails    => staging_profile.fetch('finishNotifyEmails', :absent),
        :promote_notify_emails  => staging_profile.fetch('promotionNotifyEmails', :absent),
        :drop_notify_emails     => staging_profile.fetch('dropNotifyEmails', :absent),

        # roles come in as a list and have to be joined into a comma-separated string
        :close_notify_roles     => Nexus::Util.a_list_or_absent(staging_profile['finishNotifyRoles']),
        :promote_notify_roles   => Nexus::Util.a_list_or_absent(staging_profile['promotionNotifyRoles']),
        :drop_notify_roles      => Nexus::Util.a_list_or_absent(staging_profile['dropNotifyRoles']),

        # just a boolean flag
        :close_notify_creator   => Nexus::Util.a_boolean_or_default(staging_profile['finishNotifyCreator'], :false),
        :promote_notify_creator => Nexus::Util.a_boolean_or_default(staging_profile['promotionNotifyCreator'], :false),
        :drop_notify_creator    => Nexus::Util.a_boolean_or_default(staging_profile['dropNotifyCreator'], :false),

        # a list of staging ruleset ids (ids, not the logical names); thus their real name has to be resolved as this is
        # used at the Puppet resource level to reference them
        :close_rulesets         => staging_profile.fetch('closeRuleSets', []).collect { |ruleset_id| known_rulesets.fetch(ruleset_id, ruleset_id) }.join(','),
        :promote_rulesets       => staging_profile.fetch('promoteRuleSets', []).collect { |ruleset_id| known_rulesets.fetch(ruleset_id, ruleset_id) }.join(',')
    }
  end

  def self.prefetch(resources)
    staging_profiles = instances
    resources.keys.each do |name|
      if provider = staging_profiles.find { |staging_profile| staging_profile.name == name }
        resources[name].provider = provider
      end
    end
  end

  def create
    begin
      Nexus::Rest.create('/service/local/staging/profiles', map_resource_to_data)
    rescue Exception => e
      raise Puppet::Error, "Error while creating #{@resource.class.name}['#{@resource[:name]}']: #{e}"
    end
  end

  def flush
    if @update_required
      begin
        Nexus::Rest.update("/service/local/staging/profiles/#{@property_hash[:id]}", map_resource_to_data)
        @property_hash = resource.to_hash
      rescue Exception => e
        raise Puppet::Error, "Error while updating #{@resource.class.name}['#{@resource[:name]}']: #{e}"
      end
    end
  end

  def destroy
    raise "The current configuration prevents the deletion of #{@resource.class.name}['#{@resource[:name]}']; If this
           change is intended, please update the configuration file (#{Nexus::Config.file_path}) in order to perform
           this change." unless Nexus::Config.can_delete_repositories

    begin
      Nexus::Rest.destroy("/service/local/staging/profiles/#{@property_hash[:id]}")
    rescue Exception => e
      raise Puppet::Error, "Error while deleting #{@resource.class.name}['#{@resource[:name]}']: #{e}"
    end
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
    known_rulesets = self.class.get_known_rulesets.invert
    data = {
        'name'                      => @resource[:name],
        'autoStagingDisabled'       => @resource[:implicitly_selectable] == :false,
        'repositoriesSearchable'    => @resource[:searchable] == :true,
        'mode'                      => @resource[:staging_mode].to_s.upcase,
        'repositoryTemplateId'      => @resource[:staging_template],
        'repositoryType'            => @resource[:repository_type],
        'repositoryTargetId'        => @resource[:repository_target],
        'promotionTargetRepository' => @resource[:release_repository],
        'targetGroups'              => @resource[:target_groups].split(','),

        # emails: expected to be comma separate list and just passed through
        'finishNotifyEmails'        => @resource[:close_notify_emails],
        'promotionNotifyEmails'     => @resource[:promote_notify_emails],
        'dropNotifyEmails'          => @resource[:drop_notify_emails],

        # roles: expected to be a real list - exploding the string
        'finishNotifyRoles'         => @resource[:close_notify_roles].split(','),
        'promotionNotifyRoles'      => @resource[:promote_notify_roles].split(','),
        'dropNotifyRoles'           => @resource[:drop_notify_roles].split(','),

        # creator: expected to be a boolean flag
        'finishNotifyCreator'       => @resource[:close_notify_creator] == :true,
        'promotionNotifyCreator'    => @resource[:promote_notify_creator] == :true,
        'dropNotifyCreator'         => @resource[:drop_notify_creator] == :true,

        # rulesets: expected to be a real list - exploding the string and translating the ruleset name to the ruleset id
        'closeRuleSets'             => @resource[:close_rulesets].split(',').collect { |ruleset_name| known_rulesets.fetch(ruleset_name, ruleset_name) },
        'promoteRuleSets'           => @resource[:promote_rulesets].split(',').collect { |ruleset_name| known_rulesets.fetch(ruleset_name, ruleset_name) }
    }
    data['id'] = @property_hash[:id] unless @property_hash[:id].nil?
    { 'data' => data }
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  mk_resource_methods

  def mark_config_dirty
    @update_required = true
  end

  def implicitly_selectable=(value)
    @update_required = true
  end

  def searchable=(value)
    @update_required = true
  end

  def staging_mode=(value)
    @update_required = true
  end

  def staging_template=(value)
    @update_required = true
  end

  def repository_type=(value)
    @update_required = true
  end

  def repository_target=(value)
    @update_required = true
  end

  def release_repository=(value)
    @update_required = true
  end

  def target_groups=(value)
    @update_required = true
  end

  def close_notify_emails=(value)
    @update_required = true
  end

  def close_notify_roles=(value)
    @update_required = true
  end

  def close_notify_creator=(value)
    @update_required = true
  end

  def close_rulesets=(value)
    @update_required = true
  end

  def promote_notify_emails=(value)
    @update_required = true
  end

  def promote_notify_roles=(value)
    @update_required = true
  end

  def promote_notify_creator=(value)
    @update_required = true
  end

  def promote_rulesets=(value)
    @update_required = true
  end

  def drop_notify_emails=(value)
    @update_required = true
  end

  def drop_notify_roles=(value)
    @update_required = true
  end

  def drop_notify_creator=(value)
    @update_required = true
  end
end
