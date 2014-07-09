require 'json'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'config.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'exception.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'rest.rb'))

Puppet::Type.type(:nexus_scheduled_task).provide(:ruby) do

  def self.instances
    begin
      repositories = Nexus::Rest.get_all_plus_n('/service/local/schedules')
      repositories['data'].collect do |scheduled_task|
        new(
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
        )
      end
    rescue => e
      raise Puppet::Error, "Error while retrieving all nexus_scheduled_task instances: #{e}"
    end
  end

  def self.prefetch(resources)
    scheduled_tasks = instances
    resources.keys.each do |name|
      if provider = scheduled_tasks.find { |scheduled_task| scheduled_task.name == name }
        resources[name].provider = provider
      end
    end
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

  mk_resource_methods

end
