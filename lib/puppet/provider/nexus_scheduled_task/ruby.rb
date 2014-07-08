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
          :ensure        => :present,
          :id            => scheduled_task['id'],
          :name          => scheduled_task['name'],
          :enabled       => scheduled_task.has_key?('enabled') ? scheduled_task['enabled'].to_s.to_sym : nil,
          :type_id       => scheduled_task['typeId'],
          :reoccurrence  => scheduled_task.has_key?('schedule') ? scheduled_task['schedule'].to_sym : nil,
          :task_settings => scheduled_task.has_key?('properties') ? map_properties_to_keyvalue_string(scheduled_task['properties']) : nil
        )
      end
    rescue => e
      raise Puppet::Error, "Error while retrieving all nexus_scheduled_task instances: #{e}"
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
