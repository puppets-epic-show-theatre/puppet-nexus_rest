require 'json'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'config.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'exception.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'rest.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'staging_ruleset.rb'))

Puppet::Type.type(:nexus_staging_ruleset).provide(:ruby) do

  confine :feature => :restclient

  def initialize(value={})
    super(value)
    @update_required = false
  end

  def self.instances
    begin
      staging_rulesets = Nexus::Rest.get_all('/service/local/staging/rule_sets')['data']
      staging_rulesets.collect { |staging_ruleset| new(map_data_to_resource(staging_ruleset)) }
    rescue => e
      raise Puppet::Error, "Error while retrieving all nexus_staging_ruleset instances: #{e}"
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
  def self.map_data_to_resource(staging_ruleset)
    {
        :ensure      => :present,
        :id          => staging_ruleset['id'],
        :name        => staging_ruleset['name'],
        :description => staging_ruleset.has_key?('description') ? staging_ruleset['description'] : :absent,
        :rules       => staging_ruleset.has_key?('rules') ? map_rules_to_list(staging_ruleset['rules']).join(',') : :absent,
    }
  end

  # Maps the rules data structure
  #
  # [
  #   {
  #     'name'   => '<ignored>',
  #     'typeId' => '<rule1_type>'
  #   },
  #   {
  #     'name'   => '<ignored>',
  #     'typeId' => '<rule2_type>'
  #   }
  # ]
  #
  # into a simple Ruby list
  #
  # [
  #   'rule 1',
  #   'rule 2'
  # ]
  #
  def self.map_rules_to_list(rules)
    enabled_rules = rules.select { |rule| rule.fetch('enabled', false) }
    enabled_rules.collect { |enabled_rule| Nexus::StagingRuleset.find_type_by_id(enabled_rule['typeId']).name }
  end

  # Maps the rules from a list back to a hash
  #
  # Reverse operation to #map_rules_to_list
  #
  def map_rules_to_hash
    @resource[:rules].split(',').collect do |rule_name|
      ruleType = Nexus::StagingRuleset.find_type_by_name(rule_name)
      {
          'name'    => ruleType.name,
          'typeId'  => ruleType.id,
          'enabled' => true
      }
    end
  end

  def self.prefetch(resources)
    staging_rulesets = instances
    resources.keys.each do |name|
      if provider = staging_rulesets.find { |staging_ruleset| staging_ruleset.name == name }
        resources[name].provider = provider
      end
    end
  end

  def create
    begin
      Nexus::Rest.create('/service/local/staging/rule_sets', map_resource_to_data)
    rescue Exception => e
      raise Puppet::Error, "Error while creating #{@resource.class.name}['#{@resource[:name]}']: #{e}"
    end
  end

  def flush
    if @update_required
      begin
        Nexus::Rest.update("/service/local/staging/rule_sets/#{@property_hash[:id]}", map_resource_to_data)
        @property_hash = resource.to_hash
      rescue Exception => e
        raise Puppet::Error, "Error while updating #{@resource.class.name}['#{@resource[:name]}']: #{e}"
      end
    end
  end

  def destroy
    begin
      Nexus::Rest.destroy("/service/local/staging/rule_sets/#{@property_hash[:id]}")
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
        'name'        => @resource[:name],
        'description' => @resource[:description],
        'rules'       => map_rules_to_hash,
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

  def description=(value)
    @update_required = true
  end

  def rules=(value)
    @update_required = true
  end

end
