require 'json'
require File.join(File.dirname(__FILE__), '..', 'nexus_global_config')
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'config.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'exception.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'rest.rb'))

Puppet::Type.type(:nexus_smtp_settings).provide(:ruby, :parent => Puppet::Provider::NexusGlobalConfig) do
  desc "Ruby-based management of the Nexus SMTP settings."

  confine :feature => :restclient

  def initialize(value={})
    super(value)
    @update_trust_store_setting = false
  end

  def self.map_config_to_resource_hash(global_config)
    smtpSettings = global_config['smtpSettings']
    nexus_trust_store_settings = get_nexus_trust_store_settings['enabled']
    {
      :hostname               => smtpSettings['host'],
      :port                   => smtpSettings['port'],
      :username               => smtpSettings['username'],
      :password               => smtpSettings['password'] ? :present : :absent,
      :communication_security => smtpSettings['sslEnabled'] == true ? :ssl : smtpSettings['tlsEnabled'] == true ? :tls : :none,
      :sender_email           => smtpSettings['systemEmailAddress'],
      :use_nexus_trust_store  => nexus_trust_store_settings ? nexus_trust_store_settings.to_s.intern : :false
    }
  end

  # Returns the current configuration of the Nexus Trust Store settings (which is just a on or off).
  #
  # Returns:
  # {
  #    'enabled': true | false
  # }
  #
  def self.get_nexus_trust_store_settings
    begin
      Nexus::Rest.get_all('/service/siesta/ssl/truststore/key/smtp/global')
    rescue => e
      raise Puppet::Error, "Error while retrieving nexus_trust_store_settings: #{e}"
    end
  end

  def map_resource_to_config
    smtpSettings = {
      'host'               => resource[:hostname],
      'port'               => resource[:port],
      'username'           => resource[:username],
      'sslEnabled'         => resource[:communication_security] == :ssl,
      'tlsEnabled'         => resource[:communication_security] == :tls,
      'systemEmailAddress' => resource[:sender_email]
    }
    smtpSettings['password'] = resource[:password_value] if resource[:password] == :present
    { 'smtpSettings' => smtpSettings }
  end

  def flush
    begin
      update_global_config if @update_required
      update_trust_store_setting if @update_trust_store_setting
      @property_hash = resource.to_hash
    rescue Exception => e
      raise Puppet::Error, "Error while updating nexus_smtp_settings #{resource[:name]}: #{e}"
    end
  end

  def update_trust_store_setting
    Nexus::Rest.update('/service/siesta/ssl/truststore/key/smtp/global', map_resource_to_nexus_trust_store_setting_data)
  end

  def map_resource_to_nexus_trust_store_setting_data
    { 'enabled' => resource[:use_nexus_trust_store] == :true }
  end

  mk_resource_methods

  def hostname=(value)
    mark_config_dirty
  end

  def port=(value)
    mark_config_dirty
  end

  def username=(value)
    mark_config_dirty
  end

  def password=(value)
    mark_config_dirty
  end

  def communication_security=(value)
    mark_config_dirty
  end

  def sender_email=(value)
    mark_config_dirty
  end

  def use_nexus_trust_store=(value)
    @update_trust_store_setting = true
  end
end
