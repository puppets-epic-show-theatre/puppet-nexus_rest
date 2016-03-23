require 'spec_helper'

describe Puppet::Type.type(:nexus_ldap_settings) do
  before :each do
    @provider_class = described_class.provide(:simple) do
      mk_resource_methods
      def flush; end
      def self.instances; []; end
    end
    described_class.stubs(:defaultprovider).returns @provider_class
  end


  describe :pre_run_check do
    specify 'should accept empty group values when :ldap_groups_as_roles is not set' do
      expect { described_class.new(
        :name => 'any',
        :ldap_groups_as_roles => false,
        :group_base_dn => '',
        :group_id_attribute => '',
        :group_member_attribute => '',
        :group_member_format => '',
        :group_object_class => ''
        ).pre_run_check }.to_not raise_error
    end

    let(:goodGroupSettings) {
      described_class.new(
        :name => 'any',
        :ldap_groups_as_roles => true,
        :group_base_dn => 'OU=groups',
        :group_id_attribute => 'cn',
        :group_member_attribute => 'member',
        :group_member_format => '${dn}',
        :group_object_class => 'group'
      )
     }

    specify 'should accept valid group values when :ldap_groups_as_roles is set' do
      expect { goodGroupSettings.pre_run_check }.to_not raise_error
    end

    specify 'should not accept empty group_base_dn when :ldap_groups_as_roles is set' do
      expect {
        settings = goodGroupSettings
        goodGroupSettings[:group_base_dn] = ''
        goodGroupSettings.pre_run_check }.to raise_error(ArgumentError)
    end

    specify 'should not accept empty group_id_attribute when :ldap_groups_as_roles is set' do
      expect {
        settings = goodGroupSettings
        goodGroupSettings[:group_id_attribute] = ''
        goodGroupSettings.pre_run_check }.to raise_error(ArgumentError)
    end

    specify 'should not accept empty group_member_attribute when :ldap_groups_as_roles is set' do
      expect {
        settings = goodGroupSettings
        goodGroupSettings[:group_member_attribute] = ''
        goodGroupSettings.pre_run_check }.to raise_error(ArgumentError)
    end

    specify 'should not accept empty group_member_format when :ldap_groups_as_roles is set' do
      expect {
        settings = goodGroupSettings
        goodGroupSettings[:group_member_format] = ''
        goodGroupSettings.pre_run_check }.to raise_error(ArgumentError)
    end

    specify 'should not accept empty group_object_class when :ldap_groups_as_roles is set' do
      expect {
        settings = goodGroupSettings
        goodGroupSettings[:group_object_class] = ''
        goodGroupSettings.pre_run_check }.to raise_error(ArgumentError)
    end
  end

  describe :hostname do
    specify 'should accept a valid hostname' do
      expect { described_class.new(:name => 'any', :hostname => 'ldap.example.com') }.to_not raise_error
    end

    specify 'should not accept empty string' do
      expect {
        described_class.new(:name => 'any', :hostname => '')
      }.to raise_error(Puppet::ResourceError, /Parameter hostname failed/)
    end
  end

  describe :port do
    specify 'should default to 389' do
      expect(described_class.new(:name => 'any')[:port]).to be(389)
    end

    specify 'should not accept empty string' do
      expect {
        described_class.new(:name => 'any', :port => '')
      }.to raise_error(Puppet::ResourceError, /Parameter port failed/)
    end

    specify 'should not accept characters' do
      expect {
        described_class.new(:name => 'any', :port => 'abc')
      }.to raise_error(Puppet::ResourceError, /Parameter port failed/)
    end

    specify 'should not accept port 0' do
      expect {
        described_class.new(:name => 'any', :port => 0)
      }.to raise_error(Puppet::ResourceError, /Parameter port failed/)
    end

    specify 'should accept port 1' do
      expect { described_class.new(:name => 'any', :port => 1) }.to_not raise_error
    end

    specify 'should accept port as string' do
      expect { described_class.new(:name => 'any', :port => '389') }.to_not raise_error
    end

    specify 'should accept port 65535' do
      expect { described_class.new(:name => 'any', :port =>  65535) }.to_not raise_error
    end

    specify 'should not accept ports larger than 65535' do
      expect {
        described_class.new(:name => 'any', :port =>  65536)
      }.to raise_error(Puppet::ResourceError, /Parameter port failed/)
    end
  end

  describe :username do
    specify 'should default to empty string' do
      expect(described_class.new(:name => 'any')[:username]).to eq('')
    end

    specify 'should accept empty string' do
      expect { described_class.new(:name => 'any', :username => '') }.to_not raise_error
    end

    specify 'should accept valid username' do
      expect { described_class.new(:name => 'any', :username => 'jdoe') }.to_not raise_error
    end
  end

  describe :password do
    specify 'should default to :absent' do
      expect(described_class.new(:name => 'any')[:password]).to eq(:absent)
    end

    specify 'should accept :present' do
      expect { described_class.new(:name => 'any', :password => :present) }.to_not raise_error
    end

    specify 'should accept :absent' do
      expect { described_class.new(:name => 'any', :password => :absent) }.to_not raise_error
    end

    specify 'should not accept anything else' do
      expect {
        described_class.new(:name => 'any', :password => 'secret')
      }.to raise_error(Puppet::ResourceError, /Parameter password failed/)
    end
  end

  describe :password_value do
    specify 'should default to secret' do
      expect(described_class.new(:name => 'any')[:password_value]).to eq('secret')
    end

    specify 'should accept empty string' do
      expect { described_class.new(:name => 'any', :password_value => '') }.to_not raise_error
    end

    specify 'should accept valid value' do
      expect { described_class.new(:name => 'any', :password_value => 'secret') }.to_not raise_error
    end
  end

  describe :protocol do
    specify 'should default to :ldap' do
      expect(described_class.new(:name => 'any')[:protocol]).to eq(:ldap)
    end

    specify 'should accept :ldaps' do
      expect { described_class.new(:name => 'any', :protocol => :ldaps) }.to_not raise_error
    end

    specify 'should not accept empty string' do
      expect {
        described_class.new(:name => 'any', :protocol => '')
      }.to raise_error(Puppet::ResourceError, /Parameter protocol failed/)
    end

    specify 'should not accept arbitrary string' do
      expect {
        described_class.new(:name => 'any', :protocol => 'invalid')
      }.to raise_error(Puppet::ResourceError, /Parameter protocol failed/)
    end
  end

  describe :authentication_scheme do
    specify 'should default to :none' do
      expect(described_class.new(:name => 'any')[:authentication_scheme]).to eq(:none)
    end

    specify 'should accept :simple' do
      expect { described_class.new(:name => 'any', :authentication_scheme => :simple) }.to_not raise_error
    end

    specify 'should accept :DIGEST_MD5' do
      expect { described_class.new(:name => 'any', :authentication_scheme => :DIGEST_MD5) }.to_not raise_error
    end

    specify 'should accept :CRAM_MD5' do
      expect { described_class.new(:name => 'any', :authentication_scheme => :CRAM_MD5) }.to_not raise_error
    end

    specify 'should not accept empty string' do
      expect {
        described_class.new(:name => 'any', :protocol => '')
      }.to raise_error(Puppet::ResourceError, /Parameter protocol failed/)
    end

    specify 'should not accept arbitrary string' do
      expect {
        described_class.new(:name => 'any', :protocol => 'invalid')
      }.to raise_error(Puppet::ResourceError, /Parameter protocol failed/)
    end
  end

  describe :search_base do
    specify 'should accept valid search_base' do
      expect { described_class.new(:name => 'any', :search_base => 'dc=example,dc=com') }.to_not raise_error
    end

    specify 'should not accept empty search_base' do
      expect {
        described_class.new(:name => 'any', :search_base => '')
      }.to raise_error(Puppet::ResourceError, /Parameter search_base failed/)
    end

  end

  describe :realm do
    specify 'should accept valid search_base' do
      expect { described_class.new(:name => 'any', :realm => 'example.com') }.to_not raise_error
    end

    specify 'should accept empty search_base' do
      expect { described_class.new(:name => 'any', :realm => '') }.to_not raise_error
    end

  end

  describe :ldap_filter do
    specify 'should accept empty string' do
      expect { described_class.new(:name => 'any', :ldap_filter => '') }.to_not raise_error
    end

    specify 'should accept valid value' do
      expect { described_class.new(:name => 'any', :ldap_filter => 'cn=john smith') }.to_not raise_error
    end
  end

  describe :email_address_attribute do
    specify 'should default to email' do
      expect(described_class.new(:name => 'any')[:email_address_attribute]).to eq('email')
    end

    specify 'should accept valid value' do
      expect { described_class.new(:name => 'any', :email_address_attribute => 'mail') }.to_not raise_error
    end
  end

  describe :user_id_attribute do
    specify 'should default to cn' do
      expect(described_class.new(:name => 'any')[:user_id_attribute]).to eq('cn')
    end

    specify 'should accept valid value' do
      expect { described_class.new(:name => 'any', :user_id_attribute => 'userCode') }.to_not raise_error
    end
  end

  describe :user_object_class do
    specify 'should default to user' do
      expect(described_class.new(:name => 'any')[:user_object_class]).to eq('user')
    end

    specify 'should accept valid value' do
      expect { described_class.new(:name => 'any', :user_object_class => 'person') }.to_not raise_error
    end
  end

  describe :user_real_name_attribute do
    specify 'should default to displayName' do
      expect(described_class.new(:name => 'any')[:user_real_name_attribute]).to eq('displayName')
    end

    specify 'should accept valid value' do
      expect { described_class.new(:name => 'any', :user_object_class => 'fullName') }.to_not raise_error
    end
  end

  describe :group_base_dn do
    specify 'should default to OU=groups' do
      expect(described_class.new(:name => 'any')[:group_base_dn]).to eq('OU=groups')
    end

    specify 'should accept valid value' do
      expect { described_class.new(:name => 'any', :group_base_dn => 'OU=subgroups,OU=groups') }.to_not raise_error
    end
  end

  describe :group_id_attribute do
    specify 'should default to cn' do
      expect(described_class.new(:name => 'any')[:group_id_attribute]).to eq('cn')
    end

    specify 'should accept valid value' do
      expect { described_class.new(:name => 'any', :group_id_attribute => 'groupName') }.to_not raise_error
    end
  end

  describe :group_member_attribute do
    specify 'should default to uniqueMember' do
      expect(described_class.new(:name => 'any')[:group_member_attribute]).to eq('uniqueMember')
    end

    specify 'should accept valid value' do
      expect { described_class.new(:name => 'any', :group_member_attribute => 'members') }.to_not raise_error
    end
  end

  describe :group_member_format do
    specify 'should default to ${dn}' do
      expect(described_class.new(:name => 'any')[:group_member_format]).to eq('${dn}')
    end

    specify 'should accept valid value' do
      expect { described_class.new(:name => 'any', :group_member_format => '${cn}') }.to_not raise_error
    end
  end

  describe :group_object_class do
    specify 'should default to group' do
      expect(described_class.new(:name => 'any')[:group_object_class]).to eq('group')
    end

    specify 'should accept valid value' do
      expect { described_class.new(:name => 'any', :group_object_class => 'role') }.to_not raise_error
    end
  end

  describe :user_subtree do
    specify 'should default to false' do
      expect(described_class.new(:name => 'any')[:user_subtree]).to be_false
    end

    specify 'should accept :true' do
      expect { described_class.new(:name => 'any', :user_subtree => :true) }.to_not raise_error
    end

    specify 'should accept :false' do
      expect { described_class.new(:name => 'any', :user_subtree => :false) }.to_not raise_error
    end
  end

  describe :group_subtree do
    specify 'should default to false' do
      expect(described_class.new(:name => 'any')[:group_subtree]).to be_false
    end

    specify 'should accept :true' do
      expect { described_class.new(:name => 'any', :group_subtree => :true) }.to_not raise_error
    end

    specify 'should accept :false' do
      expect { described_class.new(:name => 'any', :group_subtree => :false) }.to_not raise_error
    end
  end

  describe :ldap_groups_as_roles do
    specify 'should default to false' do
      expect(described_class.new(:name => 'any')[:ldap_groups_as_roles]).to be_false
    end

    specify 'should accept :true' do
      expect { described_class.new(:name => 'any', :ldap_groups_as_roles => :true) }.to_not raise_error
    end

    specify 'should accept :false' do
      expect { described_class.new(:name => 'any', :ldap_groups_as_roles => :false) }.to_not raise_error
    end
  end
end
