require 'spec_helper'

describe Puppet::Type.type(:nexus_scheduled_task) do
  let(:defaults) { {:name => 'any', :type_id => 'any', :reoccurrence => :manual} }
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

  describe :enabled do
    specify 'should default to true' do
      expect(described_class.new(defaults)[:enabled]).to eq(:true)
    end

    specify 'should accept :true' do
      expect { described_class.new(defaults.merge(:enabled => :true)) }.to_not raise_error
    end

    specify 'should accept :false' do
      expect { described_class.new(defaults.merge(:enabled => :false)) }.to_not raise_error
    end

    specify 'should not accept empty string' do
      expect {
        described_class.new(defaults.merge(:enabled => ''))
      }.to raise_error(Puppet::ResourceError, /Parameter enabled failed/)
    end
  end

  describe :type_id do
    specify 'should accept regular type' do
      expect { described_class.new(defaults.merge(:type_id => 'OptimizeIndexTask')) }.to_not raise_error
    end

    specify 'should not accept empty value' do
      expect { described_class.new(defaults.merge(:type_id => '')) }.to raise_error(Puppet::Error, /Type id must not be empty/)
    end
  end

  describe :task_settings do
    specify 'should accept empty hash' do
      expect { described_class.new(defaults.merge(:task_settings => {})) }.to_not raise_error
    end

    specify 'should accept hash with one entry' do
      expect { described_class.new(defaults.merge(:task_settings => {:foo => 'bar'})) }.to_not raise_error
    end

    specify 'should not accept hash with invalid characters' do
      expect { described_class.new(defaults.merge(:task_settings => {:foo => 'b=r'})) }.to raise_error(Puppet::Error, /contains restricted character: =/)
    end

    specify 'should accept hash with two entries' do
      expect { described_class.new(defaults.merge(:task_settings => {:prop1 => 'value1', :prop2 => 'value2'})) }.to_not raise_error
    end
  end

  describe :alert_email do
    specify 'should default to empty email address' do
      expect(described_class.new(defaults)[:alert_email]).to eq('')
    end

    specify 'should accept valid email address' do
      expect { described_class.new(defaults.merge(:alert_email => 'jdoe@example.com')) }.to_not raise_error
    end

    specify 'should accept empty email address' do
      expect { described_class.new(defaults.merge(:alert_email => '')) }.to_not raise_error
    end

    specify 'should not accept invalid email address' do
      expect { described_class.new(defaults.merge(:alert_email => 'invalid')) }.to raise_error(Puppet::Error, /Alert email must be a valid email address/)
    end
  end

  describe :reoccurrence do
    specify 'should accept valid value' do
      expect { described_class.new(defaults.merge(:reoccurrence => :manual)) }.to_not raise_error
    end

    specify 'should not accept empty value' do
      expect { described_class.new(defaults.merge(:reoccurrence => '')) }.to raise_error(Puppet::Error, /Invalid value/)
    end

    specify 'should not accept daily without start_date' do
      expect { described_class.new(defaults.merge(:reoccurrence => :daily)) }.to raise_error(Puppet::Error, /requires start_date/)
    end
    specify 'should not accept advanced without cron_expression' do
      expect { described_class.new(defaults.merge(:reoccurrence => :advanced, :start_date => 0)) }.to raise_error(Puppet::Error, /requires cron_expression/)
    end
  end

  describe :cron_expression do
    specify 'should default to empty value' do
      expect(described_class.new(defaults)[:cron_expression]).to eq('')
    end

    specify 'should accept regular cron expression' do
      expect { described_class.new(defaults.merge(:cron_expression => '0 0 12 * * ?')) }.to_not raise_error
    end
  end
end
