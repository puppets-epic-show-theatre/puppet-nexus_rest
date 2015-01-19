require 'spec_helper'

describe Puppet::Type.type(:nexus_staging_profile) do
  let(:defaults) do
    {
        :name               => 'any',
        :repository_target  => 'repository-target',
        :release_repository => 'Public repository',
        :target_groups      => 'Public artifacts'
    }
  end

  before :each do
    @provider_class = described_class.provide(:simple) do
      mk_resource_methods
      def flush; end
      def self.instances; []; end
    end
    described_class.stubs(:defaultprovider).returns @provider_class
  end

  describe :ensure do
    specify 'should accept present' do
      expect { described_class.new(defaults.merge(:ensure => :present)) }.to_not raise_error
    end

    specify 'should accept absent' do
      expect { described_class.new(defaults.merge(:ensure => :absent)) }.to_not raise_error
    end
  end

  describe :implicitly_selectable do
    specify 'should default to true' do
      defaults.delete(:implicitly_selectable)

      expect(described_class.new(defaults)[:implicitly_selectable]).to eq(:true)
    end

    specify 'should accept true' do
      expect { described_class.new(defaults.merge(:implicitly_selectable => :true)) }.to_not raise_error
    end

    specify 'should accept false' do
      expect { described_class.new(defaults.merge(:implicitly_selectable => :false)) }.to_not raise_error
    end

    specify 'should not accept empty string' do
      expect { described_class.new(defaults.merge(:implicitly_selectable => '')) }.to raise_error(Puppet::ResourceError, /not an empty string/)
    end
  end

  describe :searchable do
    specify 'should default to true' do
      defaults.delete(:searchable)

      expect(described_class.new(defaults)[:searchable]).to eq(:true)
    end

    specify 'should accept true' do
      expect { described_class.new(defaults.merge(:searchable => :true)) }.to_not raise_error
    end

    specify 'should accept false' do
      expect { described_class.new(defaults.merge(:searchable => :false)) }.to_not raise_error
    end

    specify 'should not accept empty string' do
      expect { described_class.new(defaults.merge(:searchable => '')) }.to raise_error(Puppet::ResourceError, /not an empty string/)
    end
  end

  describe :staging_template do
    specify 'should default to `default_hosted_release`' do
      defaults.delete(:staging_template)

      expect(described_class.new(defaults)[:staging_template]).to eq('default_hosted_release')
    end

    specify 'should accept valid string' do
      expect { described_class.new(defaults.merge(:staging_template => 'some-template')) }.to_not raise_error
    end

    specify 'should not accept empty string' do
      expect { described_class.new(defaults.merge(:staging_template => '')) }.to raise_error(Puppet::ResourceError, /must be a non-empty string/)
    end
  end

  describe :repository_type do
    specify 'should default to `maven2`' do
      defaults.delete(:repository_type)

      expect(described_class.new(defaults)[:repository_type]).to eq(:maven2)
    end

    specify 'should accept valid string' do
      expect { described_class.new(defaults.merge(:repository_type => 'typeX')) }.to_not raise_error
    end

    specify 'should not accept empty string' do
      expect { described_class.new(defaults.merge(:repository_type => '')) }.to raise_error(Puppet::ResourceError, /must be a non-empty string/)
    end
  end

  describe :repository_target do
    specify 'should be required' do
      defaults.delete(:repository_target)

      expect { described_class.new(defaults) }.to raise_error(Puppet::ResourceError, /is a mandatory property/)
    end

    specify 'should not be validated when ensure => absent' do
      defaults.delete(:repository_target)

      expect { described_class.new(defaults.merge(:ensure => :absent)) }.to_not raise_error
    end

    specify 'should accept valid string' do
      expect { described_class.new(defaults.merge(:repository_target => 'all')) }.to_not raise_error
    end

    specify 'should not accept empty string' do
      expect { described_class.new(defaults.merge(:repository_target => '')) }.to raise_error(Puppet::ResourceError, /must be a non-empty string/)
    end
  end

  describe :release_repository do
    specify 'should be required' do
      defaults.delete(:release_repository)

      expect { described_class.new(defaults) }.to raise_error(Puppet::ResourceError, /is a mandatory property/)
    end

    specify 'should not be required when ensure => absent' do
      defaults.delete(:release_repository)

      expect { described_class.new(defaults.merge(:ensure => :absent)) }.to_not raise_error
    end

    specify 'should accept valid Maven repository' do
      expect { described_class.new(defaults.merge(:release_repository => 'Public Repository')) }.to_not raise_error
    end

    specify 'should not accept empty string' do
      expect { described_class.new(defaults.merge(:release_repository => '')) }.to raise_error(Puppet::ResourceError, /must be a non-empty string/)
    end
  end

  describe :target_groups do
    specify 'should be required' do
      defaults.delete(:target_groups)

      expect { described_class.new(defaults) }.to raise_error(Puppet::ResourceError, /is a mandatory property/)
    end

    specify 'should not be required when ensure => absent' do
      defaults.delete(:target_groups)

      expect { described_class.new(defaults.merge(:ensure => :absent)) }.to_not raise_error
    end

    specify 'should not accept empty array' do
      expect { described_class.new(defaults.merge(:target_groups => [])) }.to raise_error(Puppet::ResourceError, /not be empty/)
    end

    specify 'should not accept empty string' do
      expect { described_class.new(defaults.merge(:target_groups => '')) }.to raise_error(Puppet::ResourceError, /not be empty/)
    end

    specify 'should accept single string' do
      expect { described_class.new(defaults.merge(:target_groups => 'repository-group-id')) }.to_not raise_error
    end

    specify 'should not accept string with comma separate list of elements' do
      expect { described_class.new(defaults.merge(:target_groups => 'group-a,group-b')) }.to raise_error(Puppet::ResourceError, /must be provided as an array/)
    end

    specify 'should accept array with single element' do
      expect { described_class.new(defaults.merge(:target_groups => ['rule-A'])) }.to_not raise_error
    end

    specify 'should accept array multiple elements' do
      expect { described_class.new(defaults.merge(:target_groups => ['group-a', 'group-b'])) }.to_not raise_error
    end
  end

  describe :close_notify_emails do
    specify 'should default to empty string' do
      defaults.delete(:close_notify_emails)

      expect(described_class.new(defaults)[:close_notify_emails]).to eq('')
    end

    specify 'should accept a single string' do
      expect { described_class.new(defaults.merge(:close_notify_emails => 'jdoe@example.com')) }.to_not raise_error
    end

    specify 'should accept an empty string' do
      expect { described_class.new(defaults.merge(:close_notify_emails => '')) }.to_not raise_error
    end

    specify 'should accept an empty array' do
      expect { described_class.new(defaults.merge(:close_notify_emails => [])) }.to_not raise_error
    end

    specify 'should accept array with single element' do
      expect { described_class.new(defaults.merge(:close_notify_emails => ['jdoe@example.com'])) }.to_not raise_error
    end

    specify 'should accept array multiple elements' do
      expect { described_class.new(defaults.merge(:close_notify_emails => ['jdoe@example.com', 'jane@example.com'])) }.to_not raise_error
    end

    specify 'should not accept invalid email addresses' do
      expect {
        described_class.new(defaults.merge(:close_notify_emails => 'invalid'))
      }.to raise_error(Puppet::ResourceError, /Invalid email address 'invalid'/)
    end

    specify 'should not accept string with comma separated list of email addresses' do
      expect {
        described_class.new(defaults.merge(:close_notify_emails => 'john@example.com,jane@example.com'))
      }.to raise_error(Puppet::ResourceError, /Multiple email addresses/)
    end
  end

  describe :close_notify_roles do
    specify 'should default to empty string' do
      defaults.delete(:close_notify_roles)

      expect(described_class.new(defaults)[:close_notify_roles]).to eq('')
    end

    specify 'should accept a single string' do
      expect { described_class.new(defaults.merge(:close_notify_roles => 'admins')) }.to_not raise_error
    end

    specify 'should accept an empty string' do
      expect { described_class.new(defaults.merge(:close_notify_roles => '')) }.to_not raise_error
    end

    specify 'should accept an empty array' do
      expect { described_class.new(defaults.merge(:close_notify_roles => [])) }.to_not raise_error
    end

    specify 'should accept array with single element' do
      expect { described_class.new(defaults.merge(:close_notify_roles => ['admins'])) }.to_not raise_error
    end

    specify 'should accept array multiple elements' do
      expect { described_class.new(defaults.merge(:close_notify_roles => ['admins', 'users'])) }.to_not raise_error
    end

    specify 'should not accept string with comma separated list of roles' do
      expect {
        described_class.new(defaults.merge(:close_notify_roles => 'admins,users'))
      }.to raise_error(Puppet::ResourceError, /Multiple roles/)
    end
  end

  describe :close_notify_creator do
    specify 'should default to true' do
      defaults.delete(:close_notify_creator)

      expect(described_class.new(defaults)[:close_notify_creator]).to eq(:true)
    end

    specify 'should accept true' do
      expect { described_class.new(defaults.merge(:close_notify_creator => :true)) }.to_not raise_error
    end

    specify 'should accept false' do
      expect { described_class.new(defaults.merge(:close_notify_creator => :false)) }.to_not raise_error
    end

    specify 'should not accept empty string' do
      expect { described_class.new(defaults.merge(:close_notify_creator => '')) }.to raise_error(Puppet::ResourceError, /not an empty string/)
    end
  end

  describe :close_rulesets do
    specify 'should default to empty string' do
      defaults.delete(:close_rulesets)

      expect(described_class.new(defaults)[:close_rulesets]).to eq('')
    end

    specify 'should accept a single string' do
      expect { described_class.new(defaults.merge(:close_rulesets => 'ruleset-1')) }.to_not raise_error
    end

    specify 'should accept an empty string' do
      expect { described_class.new(defaults.merge(:close_rulesets => '')) }.to_not raise_error
    end

    specify 'should accept an empty array' do
      expect { described_class.new(defaults.merge(:close_rulesets => [])) }.to_not raise_error
    end

    specify 'should accept array with single element' do
      expect { described_class.new(defaults.merge(:close_rulesets => ['ruleset-1'])) }.to_not raise_error
    end

    specify 'should accept array multiple elements' do
      expect { described_class.new(defaults.merge(:close_rulesets => ['ruleset-2', 'ruleset-2'])) }.to_not raise_error
    end

    specify 'should not accept string with comma separated list of roles' do
      expect {
        described_class.new(defaults.merge(:close_rulesets => 'ruleset-1,ruleset-2'))
      }.to raise_error(Puppet::ResourceError, /Multiple rulesets/)
    end
  end

  describe :promote_notify_emails do
    specify 'should default to empty string' do
      defaults.delete(:promote_notify_emails)

      expect(described_class.new(defaults)[:promote_notify_emails]).to eq('')
    end

    specify 'should accept a single string' do
      expect { described_class.new(defaults.merge(:promote_notify_emails => 'jdoe@example.com')) }.to_not raise_error
    end

    specify 'should accept an empty string' do
      expect { described_class.new(defaults.merge(:promote_notify_emails => '')) }.to_not raise_error
    end

    specify 'should accept an empty array' do
      expect { described_class.new(defaults.merge(:promote_notify_emails => [])) }.to_not raise_error
    end

    specify 'should accept array with single element' do
      expect { described_class.new(defaults.merge(:promote_notify_emails => ['jdoe@example.com'])) }.to_not raise_error
    end

    specify 'should accept array multiple elements' do
      expect { described_class.new(defaults.merge(:promote_notify_emails => ['jdoe@example.com', 'jane@example.com'])) }.to_not raise_error
    end

    specify 'should not accept invalid email addresses' do
      expect {
        described_class.new(defaults.merge(:promote_notify_emails => 'invalid'))
      }.to raise_error(Puppet::ResourceError, /Invalid email address 'invalid'/)
    end
  end

  describe :promote_notify_roles do
    specify 'should default to empty string' do
      defaults.delete(:promote_notify_roles)

      expect(described_class.new(defaults)[:promote_notify_roles]).to eq('')
    end

    specify 'should accept a single string' do
      expect { described_class.new(defaults.merge(:promote_notify_roles => 'admins')) }.to_not raise_error
    end

    specify 'should accept an empty string' do
      expect { described_class.new(defaults.merge(:promote_notify_roles => '')) }.to_not raise_error
    end

    specify 'should accept an empty array' do
      expect { described_class.new(defaults.merge(:promote_notify_roles => [])) }.to_not raise_error
    end

    specify 'should accept array with single element' do
      expect { described_class.new(defaults.merge(:promote_notify_roles => ['admins'])) }.to_not raise_error
    end

    specify 'should accept array multiple elements' do
      expect { described_class.new(defaults.merge(:promote_notify_roles => ['admins', 'users'])) }.to_not raise_error
    end

    specify 'should not accept string with comma separated list of roles' do
      expect {
        described_class.new(defaults.merge(:promote_notify_roles => 'admins,users'))
      }.to raise_error(Puppet::ResourceError, /Multiple roles/)
    end
  end

  describe :promote_notify_creator do
    specify 'should default to true' do
      defaults.delete(:promote_notify_creator)

      expect(described_class.new(defaults)[:promote_notify_creator]).to eq(:true)
    end

    specify 'should accept true' do
      expect { described_class.new(defaults.merge(:promote_notify_creator => :true)) }.to_not raise_error
    end

    specify 'should accept false' do
      expect { described_class.new(defaults.merge(:promote_notify_creator => :false)) }.to_not raise_error
    end

    specify 'should not accept empty string' do
      expect { described_class.new(defaults.merge(:promote_notify_creator => '')) }.to raise_error(Puppet::ResourceError, /not an empty string/)
    end
  end

  describe :promote_rulesets do
    specify 'should default to empty string' do
      defaults.delete(:promote_rulesets)

      expect(described_class.new(defaults)[:promote_rulesets]).to eq('')
    end

    specify 'should accept a single string' do
      expect { described_class.new(defaults.merge(:promote_rulesets => 'ruleset-1')) }.to_not raise_error
    end

    specify 'should accept an empty string' do
      expect { described_class.new(defaults.merge(:promote_rulesets => '')) }.to_not raise_error
    end

    specify 'should accept an empty array' do
      expect { described_class.new(defaults.merge(:promote_rulesets => [])) }.to_not raise_error
    end

    specify 'should accept array with single element' do
      expect { described_class.new(defaults.merge(:promote_rulesets => ['ruleset-1'])) }.to_not raise_error
    end

    specify 'should accept array multiple elements' do
      expect { described_class.new(defaults.merge(:promote_rulesets => ['ruleset-2', 'ruleset-2'])) }.to_not raise_error
    end

    specify 'should not accept string with comma separated list of roles' do
      expect {
        described_class.new(defaults.merge(:promote_rulesets => 'ruleset-1,ruleset-2'))
      }.to raise_error(Puppet::ResourceError, /Multiple rulesets/)
    end
  end

  describe :drop_notify_emails do
    specify 'should default to empty string' do
      defaults.delete(:drop_notify_emails)

      expect(described_class.new(defaults)[:drop_notify_emails]).to eq('')
    end

    specify 'should accept a single string' do
      expect { described_class.new(defaults.merge(:drop_notify_emails => 'jdoe@example.com')) }.to_not raise_error
    end

    specify 'should accept an empty string' do
      expect { described_class.new(defaults.merge(:drop_notify_emails => '')) }.to_not raise_error
    end

    specify 'should accept an empty array' do
      expect { described_class.new(defaults.merge(:drop_notify_emails => [])) }.to_not raise_error
    end

    specify 'should accept array with single element' do
      expect { described_class.new(defaults.merge(:drop_notify_emails => ['jdoe@example.com'])) }.to_not raise_error
    end

    specify 'should accept array multiple elements' do
      expect { described_class.new(defaults.merge(:drop_notify_emails => ['jdoe@example.com', 'jane@example.com'])) }.to_not raise_error
    end

    specify 'should not accept invalid email addresses' do
      expect {
        described_class.new(defaults.merge(:drop_notify_emails => 'invalid'))
      }.to raise_error(Puppet::ResourceError, /Invalid email address 'invalid'/)
    end

    specify 'should not accept string with comma separated list of email addresses' do
      expect {
        described_class.new(defaults.merge(:drop_notify_emails => 'john@example.com,jane@example.com'))
      }.to raise_error(Puppet::ResourceError, /Multiple email addresses/)
    end
  end

  describe :drop_notify_roles do
    specify 'should default to empty string' do
      defaults.delete(:drop_notify_roles)

      expect(described_class.new(defaults)[:drop_notify_roles]).to eq('')
    end

    specify 'should accept a single string' do
      expect { described_class.new(defaults.merge(:drop_notify_roles => 'admins')) }.to_not raise_error
    end

    specify 'should accept an empty string' do
      expect { described_class.new(defaults.merge(:drop_notify_roles => '')) }.to_not raise_error
    end

    specify 'should accept an empty array' do
      expect { described_class.new(defaults.merge(:drop_notify_roles => [])) }.to_not raise_error
    end

    specify 'should accept array with single element' do
      expect { described_class.new(defaults.merge(:drop_notify_roles => ['admins'])) }.to_not raise_error
    end

    specify 'should accept array multiple elements' do
      expect { described_class.new(defaults.merge(:drop_notify_roles => ['admins', 'users'])) }.to_not raise_error
    end

    specify 'should not accept string with comma separated list of roles' do
      expect {
        described_class.new(defaults.merge(:drop_notify_roles => 'admins,users'))
      }.to raise_error(Puppet::ResourceError, /Multiple roles/)
    end
  end

  describe :drop_notify_creator do
    specify 'should default to true' do
      defaults.delete(:drop_notify_creator)

      expect(described_class.new(defaults)[:drop_notify_creator]).to eq(:true)
    end

    specify 'should accept true' do
      expect { described_class.new(defaults.merge(:drop_notify_creator => :true)) }.to_not raise_error
    end

    specify 'should accept false' do
      expect { described_class.new(defaults.merge(:drop_notify_creator => :false)) }.to_not raise_error
    end

    specify 'should not accept empty string' do
      expect { described_class.new(defaults.merge(:drop_notify_creator => '')) }.to raise_error(Puppet::ResourceError, /not an empty string/)
    end
  end

end
