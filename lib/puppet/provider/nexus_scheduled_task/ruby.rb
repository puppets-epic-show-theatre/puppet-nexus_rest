require 'json'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'config.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'exception.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'rest.rb'))

Puppet::Type.type(:nexus_scheduled_task).provide(:ruby) do

  def self.instances
    begin
      repositories = Nexus::Rest.get_all_plus_n('/service/local/schedules')
      repositories['data'].collect { |scheduled_task| new(map_data_to_resource(scheduled_task)) }
    rescue => e
      raise Puppet::Error, "Error while retrieving all nexus_scheduled_task instances: #{e}"
    end
  end

  # Map the current global configuration to a hash which is used to create a new resource instance.
  #
  # scheduled_task: A map of attributes as received from the scheduled task REST resource except that leading data has
  # been stripped.
  # {
  #    ...
  #    'name': ...
  #    'enabled': ...
  #    'typeId': ...
  #    'properties': ...
  #    ...
  # }
  #
  # returns: A map of data representing the Puppet resource state.
  # {
  #    :puppet_attribute_1 => ...,
  #    :puppet_attribute_2 => ...,
  #    :puppet_attribute_3 => ...,
  # }
  #
  def self.map_data_to_resource(scheduled_task)
    {
      :ensure          => :present,
      :id              => scheduled_task['id'],
      :name            => scheduled_task['name'],
      :enabled         => scheduled_task.has_key?('enabled') ? scheduled_task['enabled'].to_s.to_sym : :absent,
      :type_id         => scheduled_task['typeId'],
      :alert_email     => scheduled_task.has_key?('alertEmail') ? scheduled_task['alertEmail'] : :absent,
      :reoccurrence    => scheduled_task.has_key?('schedule') ? scheduled_task['schedule'].to_sym : :absent,
      :task_settings   => scheduled_task.has_key?('properties') ? map_properties_to_keyvalue_string(scheduled_task['properties']) : :absent,
      :start_date      => scheduled_task.has_key?('startDate') ? Integer(scheduled_task['startDate']) : :absent,
      :start_time      => scheduled_task.has_key?('startTime') ? scheduled_task['startTime'] : :absent,
      :recurring_day   => scheduled_task.has_key?('recurringDay') ? scheduled_task['recurringDay'].join(',') : :absent,
      :recurring_time  => scheduled_task.has_key?('recurringTime') ? scheduled_task['recurringTime'] : :absent,
      :cron_expression => scheduled_task.has_key?('cronCommand') ? scheduled_task['cronCommand'] : :absent
    }
  end

  # Maps the properties data structure
  #
  # [
  #   {
  #     'key'   => '<key1>',
  #     'value' => '<value1>'
  #   },
  #   {
  #     'key'   => '<key2>',
  #     'value' => '<value2>'
  #   }
  # ]
  #
  # into a string as expected by the keyvalue property
  #
  # <key1>=<value1>;<key2>=<value2>
  #
  def self.map_properties_to_keyvalue_string(properties)
    properties.collect { |pair| "#{pair['key']}=#{pair['value']}" }.join(';')
  end

  def self.prefetch(resources)
    scheduled_tasks = instances
    resources.keys.each do |name|
      if provider = scheduled_tasks.find { |scheduled_task| scheduled_task.name == name }
        resources[name].provider = provider
      end
    end
  end

  def create
    begin
      Nexus::Rest.create('/service/local/schedules', map_resource_to_data)
    rescue Exception => e
      raise Puppet::Error, "Error while creating Nexus_scheduled_task['#{resource[:name]}']: #{e}"
    end
  end


  def flush
  end

  def destroy
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
      'name'       => resource[:name],
      'enabled'    => resource[:enabled] == :true,
      'typeId'     => resource[:type_id],
      'schedule'   => resource[:reoccurrence].to_s,
      'properties' => map_keyvalue_string_to_properties,
    }
    data['id'] = resource[:id] unless resource[:id] == :absent
    data['alertEmail'] = resource[:alert_email] unless resource[:alert_email] == :absent
    data['startDate'] = resource[:start_date].to_s unless resource[:start_date]  == :absent
    data['startTime'] = resource[:start_time] unless resource[:start_time] == :absent
    data['recurringDay'] = resource[:recurring_day].split(',') unless resource[:recurring_day] == :absent
    data['recurringTime'] = resource[:recurring_time] unless resource[:recurring_time] == :absent
    data['cronCommand'] = resource[:cron_expression] unless resource[:cron_expression] == :absent
    { 'data' => data }
  end

  def map_keyvalue_string_to_properties
    resource[:task_settings].split(';').collect do |pair|
      pair_splitted = pair.split('=')
      key = pair_splitted[0]
      value = pair_splitted[1].nil? ? '' : pair_splitted[1]
      { 'key' => key, 'value' => value }
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  mk_resource_methods

end
