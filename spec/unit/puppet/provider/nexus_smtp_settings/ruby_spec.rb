require 'spec_helper'

type_class = Puppet::Type.type(:nexus_smtp_settings)
provider_class = type_class.provider(:ruby)

describe provider_class do
  let(:settings_rest_resource) { '/service/local/global_settings/current' }
  let(:nexus_trust_store_rest_resource) { '/service/siesta/ssl/truststore/key/smtp/global' }
  before(:each) do
    Nexus::Config.stub(:resolve).and_return('http://example.com/foobar')
  end

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

  describe :instances do
    let(:data) do
      {
        'data' => {
          'smtpSettings' => {
            'host'               => 'mail.example.com',
            'port'               => 25,
            'username'           => "",
            'systemEmailAddress' => 'nexus@example.com',
            'sslEnabled'         => false,
            'tlsEnabled'         => false
          }
        }
      }
    end
    describe 'by default' do
      let(:current_settings) do
        Nexus::Rest.should_receive(:get_all).with(settings_rest_resource).and_return(data)
        Nexus::Rest.should_receive(:get_all).with(nexus_trust_store_rest_resource).and_return({'enabled' => false})
        described_class.instances[0]
      end

      specify 'should raise a human readable error message if the operation failed' do
        Nexus::Rest.should_receive(:get_all).and_raise('Operation failed')
        expect { described_class.instances }.to raise_error(Puppet::Error, /Error while retrieving settings/)
      end
      specify { expect(current_settings.name).to eq('current') }
      specify { expect(current_settings.hostname).to eq('mail.example.com') }
      specify { expect(current_settings.port).to eq(25) }
      specify { expect(current_settings.username).to eq('') }
      specify { expect(current_settings.password).to eq(:absent) }
      specify { expect(current_settings.sender_email).to eq('nexus@example.com') }
      specify { expect(current_settings.communication_security).to eq(:none) }
      specify { expect(current_settings.use_nexus_trust_store).to eq(:false) }
    end

    describe 'with ssl enabled' do
      let(:current_settings) do
        data['data']['smtpSettings']['sslEnabled'] = true
        Nexus::Rest.should_receive(:get_all).with(settings_rest_resource).and_return(data)
        Nexus::Rest.should_receive(:get_all).with(nexus_trust_store_rest_resource).and_return({'enabled' => false})
        described_class.instances[0]
      end

      specify { expect(current_settings.communication_security).to eq(:ssl) }
    end

    describe 'with tls enabled' do
      let(:current_settings) do
        data['data']['smtpSettings']['tlsEnabled'] = true
        Nexus::Rest.should_receive(:get_all).with(settings_rest_resource).and_return(data)
        Nexus::Rest.should_receive(:get_all).with(nexus_trust_store_rest_resource).and_return({'enabled' => false})
        described_class.instances[0]
      end

      specify { expect(current_settings.communication_security).to eq(:tls) }
    end

    describe 'with password set' do
      let(:current_settings) do
        data['data']['smtpSettings']['password'] = '|$|N|E|X|U|S|$|'
        Nexus::Rest.should_receive(:get_all).with(settings_rest_resource).and_return(data)
        Nexus::Rest.should_receive(:get_all).with(nexus_trust_store_rest_resource).and_return({'enabled' => false})
        described_class.instances[0]
      end

      specify { expect(current_settings.password).to eq(:present) }
    end
  end

  describe :flush do
    before (:each) do
      Nexus::Config.stub(:resolve).and_return('http://example.com/foobar')
      Nexus::Rest.stub(:get_all).and_return({'data' => {'otherdata' => 'foobar'}})
    end

    specify 'should raise a human readable error message if the operation failed' do
      provider.hostname = 'mail2.example.com'
      Nexus::Rest.should_receive(:update).and_raise('Operation failed')
      expect { provider.flush }.to raise_error(Puppet::Error, /Error while updating nexus_smtp_settings current/)
    end
  end

  describe :update_smtp_settings do
    before (:each) do
      Nexus::Config.stub(:resolve).and_return('http://example.com/foobar')
      Nexus::Rest.stub(:get_all).and_return({'data' => {'otherdata' => 'foobar'}})
    end

    specify 'should use /service/local/global_settings/current to update most of the SMTP configuration' do
      Nexus::Rest.should_receive(:update).with(settings_rest_resource, anything)
      expect { provider.update_smtp_settings }.to_not raise_error
    end

    specify 'should add unmanaged parts of the current configuration with the new one' do
      Nexus::Rest.should_receive(:update).with(anything, 'data' => hash_including('otherdata' => 'foobar'))
      expect { provider.update_smtp_settings }.to_not raise_error
    end

    specify 'should call REST_RESOURCE to fetch the current configuration' do
      Nexus::Rest.stub(:update)
      Nexus::Rest.should_receive(:get_all).with(anything)
      expect { provider.update_smtp_settings }.to_not raise_error
    end

    specify 'should map hostname to host' do
      resource[:hostname] = 'mail2.example.com'
      Nexus::Rest.should_receive(:update).with(anything, 'data' => hash_including('smtpSettings' => hash_including('host' => 'mail2.example.com')))
      expect { provider.update_smtp_settings }.to_not raise_error
    end

    specify 'should update port' do
      resource[:port] = 465
      Nexus::Rest.should_receive(:update).with(anything, 'data' => hash_including('smtpSettings' => hash_including('port' => 465)))
      expect { provider.update_smtp_settings }.to_not raise_error
    end

    specify 'should update username' do
      resource[:username] = 'jdoe'
      Nexus::Rest.should_receive(:update).with(anything, 'data' => hash_including('smtpSettings' => hash_including('username' => 'jdoe')))
      expect { provider.update_smtp_settings }.to_not raise_error
    end

    specify 'should update password' do
      resource[:password] = :present
      resource[:password_value] = 'supersecret'
      Nexus::Rest.should_receive(:update).with(anything, 'data' => hash_including('smtpSettings' => hash_including('password' => 'supersecret')))
      expect { provider.update_smtp_settings }.to_not raise_error
    end

    specify 'should update empty password' do
      resource[:password] = :present
      resource[:password_value] = ''
      Nexus::Rest.should_receive(:update).with(anything, 'data' => hash_including('smtpSettings' => hash_including('password' => '')))
      expect { provider.update_smtp_settings }.to_not raise_error
    end

    specify 'should omit password when value is :absent' do
      resource[:password] = :absent
      resource[:password_value] = 'supersecret'
      Nexus::Rest.should_receive(:update).with(anything, 'data' => hash_including('smtpSettings' => hash_excluding('password' => anything())))
      expect { provider.update_smtp_settings }.to_not raise_error
    end

    specify 'should set ssl_enabled = false and tls_enabled = false for communication_security => :none' do
      resource[:communication_security] = :none
      Nexus::Rest.should_receive(:update).with(anything, 'data' => hash_including('smtpSettings' => hash_including('ssl_enabled' => false)))
      expect { provider.update_smtp_settings }.to_not raise_error
    end

    specify 'should set ssl_enabled = true and tls_enabled = false for communication_security => :ssl' do
      resource[:communication_security] = :ssl
      Nexus::Rest.should_receive(:update).with(anything, 'data' => hash_including('smtpSettings' => hash_including('ssl_enabled' => true)))
      expect { provider.update_smtp_settings }.to_not raise_error
    end

    specify 'should set ssl_enabled = false and tls_enabled = true for communication_security => :tls' do
      resource[:communication_security] = :tls
      Nexus::Rest.should_receive(:update).with(anything, 'data' => hash_including('smtpSettings' => hash_including('ssl_enabled' => false)))
      expect { provider.update_smtp_settings }.to_not raise_error
    end

    specify 'should map sender_email to systemEmailAddress' do
      resource[:sender_email] = 'nexus@example.com'
      Nexus::Rest.should_receive(:update).with(anything, 'data' => hash_including('smtpSettings' => hash_including('systemEmailAddress' => 'nexus@example.com')))
      expect { provider.update_smtp_settings }.to_not raise_error
    end
  end

  describe :update_nexus_trust do
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
