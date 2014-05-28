require 'json'
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'config.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'exception.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'rest.rb'))

Puppet::Type.type(:nexus_smtp_settings).provide(:ruby) do
  desc "Ruby-based management of the Nexus SMTP settings."

  def initialize(value={})
    super(value)
    @update_smtp_settings = false
    @update_trust_store_setting = false
  end

  def self.instances
    begin
      # we only support the current configuration; the other existing configuration - default - looks quite different
      resource_state = { :name => 'current' }
      resource_state = resource_state.merge(map_smtp_settings_data_to_resource(Nexus::Rest.get_all('/service/local/global_settings/current')))
      resource_state = resource_state.merge(map_nexus_trust_store_setting_data_to_resource(Nexus::Rest.get_all('/service/siesta/ssl/truststore/key/smtp/global')))
      [ new(resource_state) ]
    rescue => e
      raise Puppet::Error, "Error while retrieving settings: #{e}"
    end
  end

  def self.prefetch(resources)
    settings = instances
    resources.keys.each do |name|
      if provider = settings.find { |setting| setting.name == name }
        resources[name].provider = provider
      end
    end
  end

  def flush
    begin
      update_smtp_settings if @update_smtp_settings
      update_trust_store_setting if @update_trust_store_setting
      @property_hash = resource.to_hash
    rescue Exception => e
      raise Puppet::Error, "Error while updating nexus_smtp_settings #{resource[:name]}: #{e}"
    end
  end

  def update_smtp_settings
    rest_resource = "/service/local/global_settings/#{resource[:name]}"
    current_settings = Nexus::Rest.get_all(rest_resource)
    current_settings['data'].merge!(map_resource_to_smtp_settings_data['data'])
    Nexus::Rest.update(rest_resource, current_settings)
  end

  def update_trust_store_setting
    Nexus::Rest.update('/service/siesta/ssl/truststore/key/smtp/global', map_resource_to_nexus_trust_store_setting_data)
  end

  def self.map_smtp_settings_data_to_resource(data)
    smtpSettings = data['data']['smtpSettings']
    {
      :hostname               => smtpSettings['host'],
      :port                   => smtpSettings['port'],
      :username               => smtpSettings['username'],
      :password               => smtpSettings['password'] ? :present : :absent,
      :communication_security => smtpSettings['sslEnabled'] == true ? :ssl : smtpSettings['tlsEnabled'] == true ? :tls : :none,
      :sender_email           => smtpSettings['systemEmailAddress'],
    }
  end

  def self.map_nexus_trust_store_setting_data_to_resource(data)
    { :use_nexus_trust_store => data['enabled'] ? data['enabled'].to_s.intern : :false }
  end

  # Returns the resource in a representation as expected by Nexus.
  #
  def map_resource_to_smtp_settings_data
    smtpSettings = {
      'host'               => resource[:hostname],
      'port'               => resource[:port],
      'username'           => resource[:username],
      'sslEnabled'         => resource[:communication_security] == :ssl,
      'tlsEnabled'         => resource[:communication_security] == :tls,
      'systemEmailAddress' => resource[:sender_email]
    }
    smtpSettings['password'] = resource[:password_value] if resource[:password] == :present

    {'data' => {'smtpSettings' => smtpSettings}}
  end

  def map_resource_to_nexus_trust_store_setting_data
    { 'enabled' => resource[:use_nexus_trust_store] == :true }
  end

  mk_resource_methods

  def hostname=(value)
    mark_smtp_settings_dirty
  end

  def port=(value)
    mark_smtp_settings_dirty
  end

  def username=(value)
    mark_smtp_settings_dirty
  end

  def password=(value)
    mark_smtp_settings_dirty
  end

  def communication_security=(value)
    mark_smtp_settings_dirty
  end

  def sender_email=(value)
    mark_smtp_settings_dirty
  end

  def use_nexus_trust_store=(value)
    @update_trust_store_setting = true
  end

  def mark_smtp_settings_dirty
    @update_smtp_settings = true
  end
end
