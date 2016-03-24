require 'json'

require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'config.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'exception.rb'))
require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus', 'rest.rb'))

Puppet::Type.type(:nexus_ldap_settings).provide(:ruby) do
  desc "Ruby-based management of the Nexus LDAP connection settings."

  confine :feature => :restclient

  @@ldap_conn_info_resource = '/service/local/ldap/conn_info'
  @@ldap_user_group_resource = '/service/local/ldap/user_group_conf'

  def initialize(value={})
    super(value)
    @update_required = false
  end

  def self.get_current_conn_info_config
    begin
      data = Nexus::Rest.get_all(@@ldap_conn_info_resource)
      data['data']
    rescue => e
      raise Puppet::Error, "Error while retrieving LDAP connection info configuration 'current': #{e}"
    end
  end

  def self.get_current_user_group_config
    begin
      data = Nexus::Rest.get_all(@@ldap_user_group_resource)
      data['data']
    rescue => e
      raise Puppet::Error, "Error while retrieving LDAP user/group configuration 'current': #{e}"
    end
  end

  def update_conn_info_config(resource)
    begin
      config = {
        :data => self.class.map_resource_to_conn_info_config(resource)
      }
      Nexus::Rest.update(@@ldap_conn_info_resource, config)
    rescue Exception => e
      raise Puppet::Error, "Error while updating LDAP connection info configuration '#{resource[:name]}': #{e}"
    end
  end

  def update_user_group_config(resource)
    begin
      config = {
        :data => self.class.map_resource_to_user_group_config(resource)
      }
      Nexus::Rest.update(@@ldap_user_group_resource, config)
    rescue Exception => e
      raise Puppet::Error, "Error while updating LDAP user/group configuration '#{resource[:name]}': #{e}"
    end
  end

  def self.map_conn_info_config_to_resource_hash(ldapSettings)
    authScheme = ldapSettings['authScheme']

    {
      :hostname                 => ldapSettings['host'],
      :port                     => ldapSettings['port'],
      :username                 => ldapSettings['systemUsername'],
      :password                 => ldapSettings['systemPassword'] ? :present : :absent,
      :search_base              => ldapSettings['searchBase'],
      :realm                    => ldapSettings['realm'],
      :protocol                 => ldapSettings['protocol'] ? ldapSettings['protocol'].to_sym : :ldap,
      :authentication_scheme    => ldapSettings['authScheme'] ? ldapSettings['authScheme'].to_sym : :none
    }
  end

  def self.map_user_group_config_to_resource_hash(ldapSettings)
    {
      :email_address_attribute  => ldapSettings['emailAddressAttribute'],
      :group_base_dn            => ldapSettings['groupBaseDn'],
      :group_id_attribute       => ldapSettings['groupIdAttribute'],
      :group_member_attribute   => ldapSettings['groupMemberAttribute'],
      :group_member_format      => ldapSettings['groupMemberFormat'],
      :group_object_class       => ldapSettings['groupObjectClass'],
      :user_password_attribute  => ldapSettings['userPasswordAttribute'],
      :user_id_attribute        => ldapSettings['userIdAttribute'],
      :user_object_class        => ldapSettings['userObjectClass'],
      :user_base_dn             => ldapSettings['userBaseDn'],
      :user_real_name_attribute => ldapSettings['userRealNameAttribute'],
      :ldap_groups_as_roles     => ldapSettings['ldapGroupsAsRoles'],
      :user_subtree             => ldapSettings['userSubtree'],
      :group_subtree            => ldapSettings['groupSubtree'],
      :ldap_filter              => ldapSettings['ldapFilter']
    }
  end

  def self.map_resource_to_conn_info_config(resource)
    authScheme = resource[:authentication_scheme]

    ldapSettings = {
      'host'                  => resource[:hostname],
      'port'                  => resource[:port],
      'systemUsername'        => resource[:username],
      'searchBase'            => resource[:search_base],
      'realm'                 => resource[:realm],
      'protocol'              => resource[:protocol],
      'authScheme'            => resource[:authentication_scheme]
    }
    ldapSettings['systemPassword'] = resource[:password_value] if resource[:password] == :present
    ldapSettings
  end

  def self.map_resource_to_user_group_config(resource)
    {
      'emailAddressAttribute' => resource[:email_address_attribute],
      'groupBaseDn'           => resource[:group_base_dn],
      'groupIdAttribute'      => resource[:group_id_attribute],
      'groupMemberAttribute'  => resource[:group_member_attribute],
      'groupMemberFormat'     => resource[:group_member_format],
      'groupObjectClass'      => resource[:group_object_class],
      'userPasswordAttribute' => resource[:user_password_attribute],
      'userIdAttribute'       => resource[:user_id_attribute],
      'userObjectClass'       => resource[:user_object_class],
      'userBaseDn'            => resource[:user_base_dn],
      'userRealNameAttribute' => resource[:user_real_name_attribute],
      'ldapGroupsAsRoles'     => resource[:ldap_groups_as_roles],
      'userSubtree'           => resource[:user_subtree],
      'groupSubtree'          => resource[:group_subtree],
      'ldapFilter'            => resource[:ldap_filter]
    }
  end

  def flush
    begin
      if @update_required
        update_conn_info_config(resource)
        update_user_group_config(resource)
        @property_hash = resource.to_hash
      end
    rescue Exception => e
      raise Puppet::Error, "Error while updating nexus_ldap_settings #{resource[:name]}: #{e}"
    end
  end

  def self.instances
    connInfoConfig = get_current_conn_info_config
    connInfoHash = map_conn_info_config_to_resource_hash(connInfoConfig)
    userGroupConfig = get_current_user_group_config
    userGroupHash = map_user_group_config_to_resource_hash(userGroupConfig)
    hash = connInfoHash.merge(userGroupHash)
    hash[:name] = 'current'
    [new(hash)]
  end

  def self.prefetch(resources)
    settings = instances
    resources.keys.each do |name|
      if provider = settings.find { |setting| setting.name == name }
        resources[name].provider = provider
      end
    end
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

  def password_value=(value)
    mark_config_dirty
  end

  def protocol=(value)
    mark_config_dirty
  end

  def authentication_scheme=(value)
    mark_config_dirty
  end

  def search_base=(value)
    mark_config_dirty
  end

  def realm=(value)
    mark_config_dirty
  end

  def email_address_attribute=(value)
    mark_config_dirty
  end

  def group_base_dn=(value)
    mark_config_dirty
  end

  def group_id_attribute=(value)
    mark_config_dirty
  end

  def group_member_attribute=(value)
    mark_config_dirty
  end

  def group_member_format=(value)
    mark_config_dirty
  end

  def group_object_class=(value)
    mark_config_dirty
  end

  def user_password_attribute=(value)
    mark_config_dirty
  end

  def user_id_attribute=(value)
    mark_config_dirty
  end

  def user_object_class=(value)
    mark_config_dirty
  end

  def user_base_dn=(value)
    mark_config_dirty
  end

  def user_real_name_attribute=(value)
    mark_config_dirty
  end

  def ldap_groups_as_roles=(value)
    mark_config_dirty
  end

  def user_subtree=(value)
    mark_config_dirty
  end

  def group_subtree=(value)
    mark_config_dirty
  end

  def ldap_filter=(value)
    mark_config_dirty
  end

  def mark_config_dirty
    @update_required = true
  end
end
