require 'json'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'config.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'exception.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'rest.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'scheduled_tasks.rb'))

Puppet::Type.type(:nexus_scheduled_task).provide(:ruby) do

  confine :feature => :restclient

  @@do_not_touch = false
  DO_NOT_TOUCH_ERROR_MESSAGE='Cannot modify nexus_scheduled_task resources due to previous failure(s)'

  def self.do_not_touch
    @@do_not_touch
  end

  def self.reset_do_not_touch
    @@do_not_touch=false
  end

  def initialize(value={})
    super(value)
    @update_required = false
  end

  def self.instances
    begin
      repositories = Nexus::Rest.get_all_plus_n('/service/local/schedules')['data']
      repositories.inject([]) do |processed_task_names, scheduled_task|
        name = scheduled_task['name']
        if processed_task_names.include?(name) then
          @@do_not_touch = true
          fail("Found multiple scheduled tasks with the same name '#{name}'. The name must be unique so Puppet is able " +
            "to match the existing task to the resource declared in the manifest. Please resolve the configuration " +
            "problem through the web interface (e.g. by renaming or deleting the duplicates ones) and run Puppet again.")
        else
          processed_task_names << name
        end
      end
      repositories.reject{|scheduled_task| scheduled_task["schedule"] == "internal"}.collect { |scheduled_task| new(map_data_to_resource(scheduled_task)) }
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
      :type            => Nexus::ScheduledTasks.find_type_by_id(scheduled_task['typeId']).name,
      :alert_email     => scheduled_task.has_key?('alertEmail') ? scheduled_task['alertEmail'] : :absent,
      :reoccurrence    => scheduled_task.has_key?('schedule') ? scheduled_task['schedule'].to_sym : :absent,
      :task_settings   => scheduled_task.has_key?('properties') ? map_properties_to_task_settings(scheduled_task['properties']) : :absent,
      :start_date      => scheduled_task.has_key?('startDate') ? start_date_formatted(Integer(scheduled_task['startDate'])) : :absent,
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
  # into a simple key-value Ruby hash
  #
  # {
  #   '<key1>' => '<value1>',
  #   '<key2>' => '<value2>',
  # }
  #
  def self.map_properties_to_task_settings(properties)
    properties.inject({}) { |result, pair| result.merge(pair['key'] => pair['value']) }
  end

  def map_task_settings_to_properties
    task_settings = @resource[:task_settings]
    task_settings.keys.sort.collect { |key| { 'key' => key, 'value' => task_settings[key] } }
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
      raise DO_NOT_TOUCH_ERROR_MESSAGE if self.class.do_not_touch
      Nexus::Rest.create('/service/local/schedules', map_resource_to_data)
    rescue Exception => e
      raise Puppet::Error, "Error while creating #{@resource.class.name}['#{@resource[:name]}']: #{e}"
    end
  end

  def flush
    if @update_required
      begin
        raise DO_NOT_TOUCH_ERROR_MESSAGE if self.class.do_not_touch
        Nexus::Rest.update("/service/local/schedules/#{@property_hash[:id]}", map_resource_to_data)
        @property_hash = resource.to_hash
      rescue Exception => e
        raise Puppet::Error, "Error while updating #{@resource.class.name}['#{@resource[:name]}']: #{e}"
      end
    end
  end

  def destroy
    begin
      raise DO_NOT_TOUCH_ERROR_MESSAGE if self.class.do_not_touch
      Nexus::Rest.destroy("/service/local/schedules/#{@property_hash[:id]}")
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
      'name'       => @resource[:name],
      'enabled'    => @resource[:enabled] == :true,
      'typeId'     => Nexus::ScheduledTasks.find_type_by_name(@resource[:type]).id,
      'schedule'   => @resource[:reoccurrence].to_s,
      'properties' => map_task_settings_to_properties,
    }
    data['id'] = @property_hash[:id] unless @property_hash[:id].nil?
    data['alertEmail'] = @resource[:alert_email] unless @resource[:alert_email] == :absent
    data['startDate'] = start_date_in_millis(@resource[:start_date]).to_s unless @resource[:start_date].nil?
    data['startTime'] = @resource[:start_time] unless @resource[:start_time].nil?
    data['recurringDay'] = @resource[:recurring_day].split(',') unless @resource[:recurring_day].nil?
    data['recurringTime'] = @resource[:recurring_time] unless @resource[:recurring_time].nil?
    data['cronCommand'] = @resource[:cron_expression] unless @resource[:cron_expression].nil?
    { 'data' => data }
  end

  #
  # Note: the current implementation essentially drops any time component of the start_date timestamp. This has to be
  # done in order to work nicely with the Nexus REST API which ...
  #
  # * Expects to receive a date as timestamp with only YYYY-MM-DD being set; all other fields like hour or minute
  #   should be set to 0 (they are not set to zero internally)
  # * Returns a date as timestamp with the time component being set (to start_time or recurring_time, depending on
  #   the reoccurrence)
  #
  # So to send back a valid start date, we have to drop the time component. Otherwise the date will start to flip
  # in every Puppet run:
  #
  # * Puppet sends the new date
  # * Nexus will add the start_time or recurring_time (depending on the reoccurrence)
  # * Start date overflows into the next day
  # * Next run, Puppet notice the date has change and wants to set it back
  # * Puppet sends the new (old) date
  # * ...
  #

  # Returns a given date in milliseconds (as expected by the Nexus API). Date expected to match match `YYYY-MM-DD`.
  #
  def start_date_in_millis(start_date_formatted)
    # see the note above
    year,month,day = /(\d{4})-(\d{2})-(\d{2})/.match(start_date_formatted).captures
    start_date = Time.gm(year, month, day)
    start_date_in_millis = start_date.to_i * 1000
    debug("Converted start_date #{start_date_formatted} to #{start_date_in_millis}")
    start_date_in_millis
  end

  # Returns the given start date as a String matching `YYYY-MM-DD`.
  #
  def self.start_date_formatted(start_date_in_millis)
    # see the note above
    start_date_formatted = Time.at(start_date_in_millis / 1000).strftime("%Y-%m-%d")
    debug("Converted startDate timestamp #{start_date_in_millis} to #{start_date_formatted}")
    start_date_formatted
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  mk_resource_methods

  def mark_config_dirty
    @update_required = true
  end

  def enabled=(value)
    @update_required = true
  end

  def type=(value)
    @update_required = true
  end

  def task_settings=(value)
    @update_required = true
  end

  def alert_email=(value)
    @update_required = true
  end

  def reoccurrence=(value)
    @update_required = true
  end

  def start_date=(value)
    @update_required = true
  end

  def start_time=(value)
    @update_required = true
  end

  def recurring_time=(value)
    @update_required = true
  end

  def recurring_day=(value)
    @update_required = true
  end

  def cron_expression=(value)
    @update_required = true
  end

end
