require 'spec_helper'

describe Puppet::Type.type(:nexus_ldap_settings).provider(:ruby) do
  describe :map_conn_info_config_to_resource_hash do
    let(:conn_info_config) do
      {
        'host'                  => 'ldap.domain.org',
        'port'                  => 123,
        'systemUsername'        => 'user',
        'systemPassword'        => 'pwd',
        'searchBase'            => 'dc=domain,dc=org',
        'realm'                 => 'domain.org',
        'protocol'              => 'ldaps',
        'authScheme'            => 'simple'
      }
    end

    let(:resource_hash) do
      described_class::map_conn_info_config_to_resource_hash(conn_info_config)
    end

    specify { expect(resource_hash[:hostname]).to eq('ldap.domain.org') }
    specify { expect(resource_hash[:port]).to eq(123) }
    specify { expect(resource_hash[:username]).to eq('user') }
    specify { expect(resource_hash[:password]).to eq(:present) }
    specify { expect(resource_hash[:search_base]).to eq('dc=domain,dc=org') }
    specify { expect(resource_hash[:realm]).to eq('domain.org') }
    specify { expect(resource_hash[:protocol]).to eq(:ldaps) }
    specify { expect(resource_hash[:authentication_scheme]).to eq(:simple) }
  end

  describe :map_user_group_config_to_resource_hash do
    let(:user_group_config) do
      {
        'emailAddressAttribute' => 'email',
        'groupBaseDn'           => 'ou=groups',
        'groupIdAttribute'      => 'cn',
        'groupMemberAttribute'  => 'member',
        'groupMemberFormat'     => '${dn}',
        'groupObjectClass'      => 'group',
        'userPasswordAttribute' => 'pass',
        'userIdAttribute'       => 'upn',
        'userObjectClass'       => 'person',
        'userBaseDn'            => 'ou=users',
        'userRealNameAttribute' => 'name',
        'ldapGroupsAsRoles'     => true,
        'userSubtree'           => false,
        'groupSubtree'          => true,
        'ldapFilter'            => '(sn=sm*)'
      }
    end

    let(:resource_hash) do
      described_class::map_user_group_config_to_resource_hash(user_group_config)
    end

    specify { expect(resource_hash[:email_address_attribute]).to eq('email') }
    specify { expect(resource_hash[:group_base_dn]).to eq('ou=groups') }
    specify { expect(resource_hash[:group_id_attribute]).to eq('cn') }
    specify { expect(resource_hash[:group_member_attribute]).to eq('member') }
    specify { expect(resource_hash[:group_member_format]).to eq('${dn}') }
    specify { expect(resource_hash[:group_object_class]).to eq('group') }
    specify { expect(resource_hash[:user_password_attribute]).to eq('pass') }
    specify { expect(resource_hash[:user_id_attribute]).to eq('upn') }
    specify { expect(resource_hash[:user_object_class]).to eq('person') }
    specify { expect(resource_hash[:user_base_dn]).to eq('ou=users') }
    specify { expect(resource_hash[:user_real_name_attribute]).to eq('name') }
    specify { expect(resource_hash[:ldap_groups_as_roles]).to eq(true) }
    specify { expect(resource_hash[:user_subtree]).to eq(false) }
    specify { expect(resource_hash[:group_subtree]).to eq(true) }
    specify { expect(resource_hash[:ldap_filter]).to eq('(sn=sm*)') }
  end

  describe :map_resource_to_conn_info_config do
    let(:resource_hash) do
      {
        :hostname              => 'ldap.domain.org',
        :port                  => 123,
        :username              => 'user',
        :password_value        => 'pwd',
        :password              => :present,
        :search_base           => 'dc=domain,dc=org',
        :realm                 => 'domain.org',
        :protocol              => 'ldaps',
        :authentication_scheme => 'simple'
      }
    end

    let(:conn_info_config) do
      described_class::map_resource_to_conn_info_config(resource_hash)
    end

    specify { expect(conn_info_config['host']).to eq('ldap.domain.org') }
    specify { expect(conn_info_config['port']).to eq(123) }
    specify { expect(conn_info_config['systemUsername']).to eq('user') }
    specify { expect(conn_info_config['systemPassword']).to eq('pwd') }
    specify { expect(conn_info_config['searchBase']).to eq('dc=domain,dc=org') }
    specify { expect(conn_info_config['realm']).to eq('domain.org') }
    specify { expect(conn_info_config['protocol']).to eq('ldaps') }
    specify { expect(conn_info_config['authScheme']).to eq('simple') }
  end

  describe :map_resource_to_user_group_config do
    let(:resource_hash) do
      {
        :email_address_attribute  => 'email',
        :group_base_dn            => 'ou=groups',
        :group_id_attribute       => 'cn',
        :group_member_attribute   => 'member',
        :group_member_format      => '${dn}',
        :group_object_class       => 'group',
        :user_password_attribute  => 'pass',
        :user_id_attribute        => 'upn',
        :user_object_class        => 'person',
        :user_base_dn             => 'ou=users',
        :user_real_name_attribute => 'name',
        :ldap_groups_as_roles     => true,
        :user_subtree             => false,
        :group_subtree            => true,
        :ldap_filter              => '(sn=sm*)'
      }
    end

    let(:user_group_config) do
      described_class::map_resource_to_user_group_config(resource_hash)
    end

    specify { expect(user_group_config['emailAddressAttribute']).to eq('email') }
    specify { expect(user_group_config['groupBaseDn']).to eq('ou=groups') }
    specify { expect(user_group_config['groupIdAttribute']).to eq('cn') }
    specify { expect(user_group_config['groupMemberAttribute']).to eq('member') }
    specify { expect(user_group_config['groupMemberFormat']).to eq('${dn}') }
    specify { expect(user_group_config['groupObjectClass']).to eq('group') }
    specify { expect(user_group_config['userPasswordAttribute']).to eq('pass') }
    specify { expect(user_group_config['userIdAttribute']).to eq('upn') }
    specify { expect(user_group_config['userObjectClass']).to eq('person') }
    specify { expect(user_group_config['userBaseDn']).to eq('ou=users') }
    specify { expect(user_group_config['userRealNameAttribute']).to eq('name') }
    specify { expect(user_group_config['ldapGroupsAsRoles']).to eq(true) }
    specify { expect(user_group_config['userSubtree']).to eq(false) }
    specify { expect(user_group_config['groupSubtree']).to eq(true) }
    specify { expect(user_group_config['ldapFilter']).to eq('(sn=sm*)') }
  end

end
