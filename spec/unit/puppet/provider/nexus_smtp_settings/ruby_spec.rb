require 'spec_helper'

type_class = Puppet::Type.type(:nexus_smtp_settings)

describe type_class.provider(:ruby) do
  let(:nexus_trust_store_rest_resource) { '/service/siesta/ssl/truststore/key/smtp/global' }
  before(:each) do
    Nexus::Config.stub(:resolve).and_return('http://example.com/foobar')
  end

  describe :map_config_to_resource_hash do
    let(:config_template) do
      {
        'smtpSettings' => {
          'host'               => 'mail.example.com',
          'port'               => 25,
          'username'           => "",
          'systemEmailAddress' => 'nexus@example.com',
          'sslEnabled'         => false,
          'tlsEnabled'         => false
        }
      }
    end

    let(:resource_hash) do
      Nexus::Rest.should_receive(:get_all).with(nexus_trust_store_rest_resource).and_return({'enabled' => false})
      described_class::map_config_to_resource_hash(global_config)
    end

    describe 'by default' do
      let(:global_config) { config_template} 

      specify { expect(resource_hash[:hostname]).to eq('mail.example.com') }
      specify { expect(resource_hash[:port]).to eq(25) }
      specify { expect(resource_hash[:username]).to eq('') }
      specify { expect(resource_hash[:password]).to eq(:absent) }
      specify { expect(resource_hash[:sender_email]).to eq('nexus@example.com') }
      specify { expect(resource_hash[:communication_security]).to eq(:none) }
      specify { expect(resource_hash[:use_nexus_trust_store]).to eq(:false) }
    end

    describe 'with ssl enabled' do
      let(:global_config) do
        config_template['smtpSettings']['sslEnabled'] = true
        config_template
      end

      specify { expect(resource_hash[:communication_security]).to eq(:ssl) }
    end

    describe 'with tls enabled' do
      let(:global_config) do
        config_template['smtpSettings']['tlsEnabled'] = true
        config_template
      end

      specify { expect(resource_hash[:communication_security]).to eq(:tls) }
    end

    describe 'with password set' do
      let(:global_config) do
        config_template['smtpSettings']['password'] = '|$|N|E|X|U|S|$|'
        config_template
      end

      specify { expect(resource_hash[:password]).to eq(:present) }
    end

    describe 'with nexus_trust_store set to true' do
      let(:resource_hash) do
        Nexus::Rest.should_receive(:get_all).with(nexus_trust_store_rest_resource).and_return({'enabled' => true})
        described_class::map_config_to_resource_hash(config_template)
      end

      specify { expect(resource_hash[:use_nexus_trust_store]).to eq(:true) }
    end
  end

  describe :map_resource_to_config do
    let(:resource) do
      {
        :hostname               => 'mail.example.com',
        :port                   => 25,
        :username               => 'jdoe',
        :password               => :present,
        :password_value         => 'supersecret',
        :communication_security => :none,
        :sender_email           => 'nexus@example.com'
      }
    end

    let(:instance) do
      instance = described_class.new()
      instance.resource = resource
      instance
    end

    specify 'should return all changes within smtpSettings hash' do
      expect(instance.map_resource_to_config.keys).to eq(['smtpSettings'])
    end

    specify 'should map hostname to host' do
      expect(instance.map_resource_to_config['smtpSettings']).to include('host' => 'mail.example.com')
    end

    specify 'should update port' do
      expect(instance.map_resource_to_config['smtpSettings']).to include('port' => 25)
    end

    specify 'should update username' do
      expect(instance.map_resource_to_config['smtpSettings']).to include('username' => 'jdoe')
    end

    specify 'should update password' do
      expect(instance.map_resource_to_config['smtpSettings']).to include('password' => 'supersecret')
    end

    specify 'should update empty password' do
      resource[:password] = :present
      resource[:password_value] = ''
      expect(instance.map_resource_to_config['smtpSettings']).to include('password' => '')
    end

    specify 'should omit password when value is :absent' do
      resource[:password] = :absent
      resource[:password_value] = 'supersecret'
      expect(instance.map_resource_to_config['smtpSettings']).to_not include('password' => anything())
    end

    specify 'should set sslEnabled = false and tlsEnabled = false for communication_security => :none' do
      resource[:communication_security] = :none
      expect(instance.map_resource_to_config['smtpSettings']).to include('sslEnabled' => false, 'tlsEnabled' => false)
    end

    specify 'should set sslEnabled = true and tlsEnabled = false for communication_security => :ssl' do
      resource[:communication_security] = :ssl
      expect(instance.map_resource_to_config['smtpSettings']).to include('sslEnabled' => true, 'tlsEnabled' => false)
    end

    specify 'should set sslEnabled = false and tlsEnabled = true for communication_security => :tls' do
      resource[:communication_security] = :tls
      expect(instance.map_resource_to_config['smtpSettings']).to include('sslEnabled' => false, 'tlsEnabled' => true)
    end

    specify 'should map sender_email to systemEmailAddress' do
      expect(instance.map_resource_to_config['smtpSettings']).to include('systemEmailAddress' => 'nexus@example.com')
    end
  end

  describe :update_nexus_trust do
    let(:resource) do
      resource = type_class.new({
        :name         => 'current',
        :hostname     => 'mail.example.com',
        :sender_email => 'nexus@example.com'
      })
    end

    let(:provider) do
      described_class.new(resource)
    end

    specify 'should use /service/siesta/ssl/truststore/key/smtp/global to the other part of the configuration' do
      Nexus::Rest.should_receive(:update).with(nexus_trust_store_rest_resource, anything)
      expect { provider.update_trust_store_setting }.to_not raise_error
    end

    specify 'should update use_nexus_trust_store' do
      resource[:use_nexus_trust_store] = :true
      Nexus::Rest.should_receive(:update).with(anything, 'enabled' => true)
      expect { provider.update_trust_store_setting }.to_not raise_error
    end
  end
end
