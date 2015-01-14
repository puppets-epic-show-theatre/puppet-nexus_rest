require 'json'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'config.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'exception.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'rest.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'util.rb'))

Puppet::Type.type(:nexus_staging_profile).provide(:ruby) do

  def initialize(value={})
    super(value)
    @update_required = false
  end

  def self.instances
    begin
      staging_profiles = Nexus::Rest.get_all('/service/local/staging/profiles')['data']
      staging_profiles.collect { |staging_profile| new(map_data_to_resource(staging_profile)) }
    rescue => e
      raise Puppet::Error, "Error while retrieving all nexus_staging_profile instances: #{e}"
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
  def self.map_data_to_resource(staging_profile)
    {
        :ensure                 => :present,
        :id                     => staging_profile['id'],
        :name                   => staging_profile['name'],
        :implicitly_selectable  => Nexus::Util.a_boolean_or_absent(staging_profile['autoStagingDisabled']),
        :searchable             => Nexus::Util.a_boolean_or_absent(staging_profile['repositoriesSearchable']),
        :staging_mode           => staging_profile.fetch('mode', :absent).to_s.downcase.intern,
        :staging_template       => staging_profile.fetch('repositoryTemplateId', :absent),
        :repository_type        => staging_profile.fetch('repositoryType', :absent),
        :repository_target      => staging_profile.fetch('repositoryTargetId', :absent),
        :release_repository     => staging_profile.fetch('promotionTargetRepository', :absent),
        :target_groups          => Nexus::Util.a_list_or_absent(staging_profile['targetGroups']),
        :close_notify_emails    => staging_profile.fetch('finishNotifyEmails', :absent),
        :close_notify_roles     => Nexus::Util.a_list_or_absent(staging_profile['finishNotifyRoles']),
        :close_notify_creator   => Nexus::Util.a_boolean_or_default(staging_profile['finishNotifyCreator'], :false),
        :close_rulesets         => Nexus::Util.a_list_or_absent(staging_profile['closeRuleSets']),
        :promote_notify_emails  => staging_profile.fetch('promotionNotifyEmails', :absent),
        :promote_notify_roles   => Nexus::Util.a_list_or_absent(staging_profile['promotionNotifyRoles']),
        :promote_notify_creator => Nexus::Util.a_boolean_or_default(staging_profile['promotionNotifyCreator'], :false),
        :promote_rulesets       => Nexus::Util.a_list_or_absent(staging_profile['promoteRuleSets']),
        :drop_notify_emails     => staging_profile.fetch('dropNotifyEmails', :absent),
        :drop_notify_roles      => Nexus::Util.a_list_or_absent(staging_profile['dropNotifyRoles']),
        :drop_notify_creator    => Nexus::Util.a_boolean_or_default(staging_profile['dropNotifyCreator'], :false)
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
    data = {
        'name'                      => @resource[:name],
        'autoStagingDisabled'       => @resource[:implicitly_selectable] == :true,
        'repositoriesSearchable'    => @resource[:searchable] == :true,
        'mode'                      => @resource[:staging_mode].to_s.upcase,
        'repositoryTemplateId'      => @resource[:staging_template],
        'repositoryType'            => @resource[:repository_type],
        'repositoryTargetId'        => @resource[:repository_target],
        'promotionTargetRepository' => @resource[:release_repository],
        'targetGroups'              => @resource[:target_groups].split(','),
        # emails: expected to be comma separate list and just passed through
        # roles: expected to be a real list - exploding the string
        # creator: expected to be a boolean flag
        # rulesets: expected to be a real list - exploding the string
        'finishNotifyEmails'        => @resource[:close_notify_emails],
        'finishNotifyRoles'         => @resource[:close_notify_roles].split(','),
        'finishNotifyCreator'       => @resource[:close_notify_creator] == :true,
        'closeRuleSets'             => @resource[:close_rulesets].split(','),
        'promotionNotifyEmails'     => @resource[:promote_notify_emails],
        'promotionNotifyRoles'      => @resource[:promote_notify_roles].split(','),
        'promotionNotifyCreator'    => @resource[:promote_notify_creator] == :true,
        'promoteRuleSets'           => @resource[:promote_rulesets].split(','),
        'dropNotifyEmails'          => @resource[:drop_notify_emails],
        'dropNotifyRoles'           => @resource[:drop_notify_roles].split(','),
        'dropNotifyCreator'         => @resource[:drop_notify_creator] == :true,

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
