require 'spec_helper'

describe Puppet::Type.type(:nexus_scheduled_task) do
  let(:defaults) { {:name => 'any', :type => 'any', :reoccurrence => :manual} }

  let(:once) do
    defaults.merge({
      :reoccurrence => :once,
      :start_date   => '2014-06-01',
      :start_time   => '10:00'
    })
  end

  let(:weekly) do
    defaults.merge({
      :reoccurrence   => :weekly,
      :start_date     => '2014-06-01',
      :recurring_day  => 'monday',
      :recurring_time => '10:00'
    })
  end

  let(:monthly) do
    defaults.merge({
      :reoccurrence   => :monthly,
      :start_date     => '2014-06-01',
      :recurring_day  => '1',
      :recurring_time => '10:00'
    })
  end

  let(:advanced) do
    defaults.merge({
      :reoccurrence    => :advanced,
      :cron_expression => '0 0 12 * * ?'
    })
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

  describe :type do
    specify 'should be mandatory when ensure => present' do
      defaults.delete(:type)

      expect { described_class.new(defaults.merge(:ensure => :present)) }.to raise_error(Puppet::Error, /Type is a mandatory property/)
    end

    specify 'should not be mandatory when ensure => absent' do
      defaults.delete(:type)

      expect { described_class.new(defaults.merge(:ensure => :absent)) }.to_not raise_error
    end

    specify 'should accept regular type' do
      expect { described_class.new(defaults.merge(:type => 'Empty Trash')) }.to_not raise_error
    end

    specify 'should not accept empty' do
      expect { described_class.new(defaults.merge(:type => '')) }.to raise_error(Puppet::Error, /Type must not be empty/)
    end
  end

  describe :task_settings do
    specify 'should not accept empty string' do
      expect { described_class.new(defaults.merge(:task_settings => '')) }.to raise_error(Puppet::Error, /Task settings must be of type Hash/)
    end

    specify 'should not accept any string at all' do
      expect { described_class.new(defaults.merge(:task_settings => 'any')) }.to raise_error(Puppet::Error, /Task settings must be of type Hash/)
    end

    specify 'should accept empty hash' do
      expect { described_class.new(defaults.merge(:task_settings => {})) }.to_not raise_error
    end

    specify 'should accept hash with one entry' do
      expect { described_class.new(defaults.merge(:task_settings => {:foo => 'bar'})) }.to_not raise_error
    end

    specify 'should accept hash with two entries' do
      expect { described_class.new(defaults.merge(:task_settings => {:prop1 => 'value1', :prop2 => 'value2'})) }.to_not raise_error
    end
  end

  describe :alert_email do
    specify 'should default to absent' do
      expect(described_class.new(defaults)[:alert_email]).to eq(:absent)
    end

    specify 'should accept valid email address' do
      expect { described_class.new(defaults.merge(:alert_email => 'jdoe@example.com')) }.to_not raise_error
    end

    specify 'should accept absent email address' do
      expect { described_class.new(defaults.merge(:alert_email => :absent)) }.to_not raise_error
    end

    specify 'should not accept empty email address' do
      expect { described_class.new(defaults.merge(:alert_email => '')) }.to raise_error(Puppet::Error, /Alert email must not be empty/)
    end

    specify 'should not accept invalid email address' do
      expect { described_class.new(defaults.merge(:alert_email => 'invalid')) }.to raise_error(Puppet::Error, /Alert email must be a valid email address/)
    end
  end

  describe :reoccurrence do
    specify 'should default to absent' do
      expect(described_class.new(defaults)[:reoccurrence]).to eq(:manual)
    end

    specify 'should not accept empty value' do
      expect { described_class.new(defaults.merge(:reoccurrence => '')) }.to raise_error(Puppet::Error, /Invalid value/)
    end

    specify 'should not be validated when ensure => absent' do
      expect { described_class.new(defaults.merge(:reoccurrence => :once, :ensure => :absent)) }.to_not raise_error
    end
  end

  describe 'reoccurence manual' do
    specify 'should just work' do
      expect { described_class.new(defaults.merge(:reoccurrence => :manual)) }.to_not raise_error
    end

    specify 'should not accept start_date' do
      expect { described_class.new(defaults.merge(:reoccurrence => :manual, :start_date => '2014-06-01')) }.to raise_error(Puppet::Error, /start_date not allowed/)
    end

    specify 'should not accept start_time' do
      expect { described_class.new(defaults.merge(:reoccurrence => :manual, :start_time => '00:00')) }.to raise_error(Puppet::Error, /start_time not allowed/)
    end

    specify 'should not accept recurring_day' do
      expect { described_class.new(defaults.merge(:reoccurrence => :manual, :recurring_day => 'monday')) }.to raise_error(Puppet::Error, /recurring_day not allowed/)
    end

    specify 'should not accept recurring_time' do
      expect { described_class.new(defaults.merge(:reoccurrence => :manual, :recurring_time => '00:00')) }.to raise_error(Puppet::Error, /recurring_time not allowed/)
    end

    specify 'should not accept cron_expression' do
      expect { described_class.new(defaults.merge(:reoccurrence => :manual, :cron_expression => '0 0 12 * * ?')) }.to raise_error(Puppet::Error, /cron_expression not allowed/)
    end
  end

  describe 'reoccurrence once' do
    specify 'should accept valid input' do
      expect { described_class.new(defaults.merge(:reoccurrence => :once, :start_date => '2014-07-14', :start_time => '00:00')) }.to_not raise_error
    end

    specify 'should not accept missing start_date' do
      expect { described_class.new(defaults.merge(:reoccurrence => :once, :start_time => '00:00')) }.to raise_error(Puppet::Error, /requires start_date/)
    end

    specify 'should not accept missing start_time' do
      expect { described_class.new(defaults.merge(:reoccurrence => :once, :start_date => '1970-01-01')) }.to raise_error(Puppet::Error, /requires start_time/)
    end

    specify 'should not accept missing start_date and start_time' do
      expect { described_class.new(defaults.merge(:reoccurrence => :once)) }.to raise_error(Puppet::Error, /requires start_date and start_time/)
    end

    specify 'should not accept recurring_day' do
      expect { described_class.new(defaults.merge(:reoccurrence => :once, :recurring_day => 'monday')) }.to raise_error(Puppet::Error, /recurring_day not allowed/)
    end

    specify 'should not accept recurring_time' do
      expect { described_class.new(defaults.merge(:reoccurrence => :once, :recurring_time => '00:00')) }.to raise_error(Puppet::Error, /recurring_time not allowed/)
    end

    specify 'should not accept cron_expression' do
      expect { described_class.new(defaults.merge(:reoccurrence => :once, :cron_expression => '0 0 12 * * ?')) }.to raise_error(Puppet::Error, /cron_expression not allowed/)
    end
  end

  describe 'reoccurrence hourly' do
    specify 'should accept valid input' do
      expect { described_class.new(defaults.merge(:reoccurrence => :hourly, :start_date => '1970-01-01', :start_time => '20:30')) }.to_not raise_error
    end

    specify 'should not accept missing start_date' do
      expect { described_class.new(defaults.merge(:reoccurrence => :hourly, :start_time => '00:00')) }.to raise_error(Puppet::Error, /requires start_date/)
    end

    specify 'should not accept missing start_time' do
      expect { described_class.new(defaults.merge(:reoccurrence => :hourly, :start_date => '1970-01-01')) }.to raise_error(Puppet::Error, /requires start_time/)
    end

    specify 'should not accept missing start_date and start_time' do
      expect { described_class.new(defaults.merge(:reoccurrence => :hourly)) }.to raise_error(Puppet::Error, /requires start_date and start_time/)
    end

    specify 'should not accept recurring_day' do
      expect { described_class.new(defaults.merge(:reoccurrence => :hourly, :recurring_day => 'monday')) }.to raise_error(Puppet::Error, /recurring_day not allowed/)
    end

    specify 'should not accept recurring_time' do
      expect { described_class.new(defaults.merge(:reoccurrence => :hourly, :recurring_time => '00:00')) }.to raise_error(Puppet::Error, /recurring_time not allowed/)
    end

    specify 'should not accept cron_expression' do
      expect { described_class.new(defaults.merge(:reoccurrence => :hourly, :cron_expression => '0 0 12 * * ?')) }.to raise_error(Puppet::Error, /cron_expression not allowed/)
    end
  end

  describe 'reoccurrence daily' do
    specify 'should accept valid input' do
      expect { described_class.new(defaults.merge(:reoccurrence => :daily, :start_date => '1970-01-01', :recurring_time => '03:00')) }.to_not raise_error
    end

    specify 'should not accept missing :start_date' do
      expect { described_class.new(defaults.merge(:reoccurrence => :daily, :recurring_time => '00:00')) }.to raise_error(Puppet::Error, /requires start_date/)
    end

    specify 'should not accept missing recurring_time' do
      expect { described_class.new(defaults.merge(:reoccurrence => :daily, :start_date => '1970-01-01')) }.to raise_error(Puppet::Error, /requires recurring_time/)
    end

    specify 'should not accept missing start_date and reccuring_time' do
      expect { described_class.new(defaults.merge(:reoccurrence => :daily)) }.to raise_error(Puppet::Error, /requires start_date and recurring_time/)
    end

    specify 'should not accept start_time' do
      expect { described_class.new(defaults.merge(:reoccurrence => :daily, :start_time => '00:00')) }.to raise_error(Puppet::Error, /start_time not allowed/)
    end

    specify 'should not accept recurring_day' do
      expect { described_class.new(defaults.merge(:reoccurrence => :daily, :recurring_day => '1')) }.to raise_error(Puppet::Error, /recurring_day not allowed/)
    end

    specify 'should not accept cron_expression' do
      expect { described_class.new(defaults.merge(:reoccurrence => :daily, :cron_expression => '0 0 12 * * ?')) }.to raise_error(Puppet::Error, /cron_expression not allowed/)
    end
  end

  describe 'reoccurrence weekly' do
    specify 'should accept valid input' do
      expect { described_class.new(defaults.merge(:reoccurrence => :weekly, :start_date => '1970-01-01', :recurring_day => 'monday', :recurring_time => '0:10')) }.to_not raise_error
    end

    specify 'should not accept missing start_date' do
      expect { described_class.new(defaults.merge(:reoccurrence => :weekly, :recurring_day => 'monday', :recurring_time => '00:00')) }.to raise_error(Puppet::Error, /requires start_date/)
    end

    specify 'should not accept missing recurring_day' do
      expect { described_class.new(defaults.merge(:reoccurrence => :weekly, :start_date => '1970-01-01', :recurring_time => '00:00')) }.to raise_error(Puppet::Error, /requires recurring_day/)
    end

    specify 'should not accept missing recurring_time' do
      expect { described_class.new(defaults.merge(:reoccurrence => :weekly, :start_date => '1970-01-01', :recurring_day => 'monday')) }.to raise_error(Puppet::Error, /requires recurring_time/)
    end

    specify 'should not accept missing start_date, recurring_day and reccuring_time' do
      expect { described_class.new(defaults.merge(:reoccurrence => :weekly)) }.to raise_error(Puppet::Error, /requires start_date and recurring_day and recurring_time/)
    end

    specify 'should not accept recurring_day as day of month' do
      expect { described_class.new(defaults.merge(:reoccurrence => :weekly, :start_date => '1970-01-01', :recurring_day => '1', :recurring_time => '0:10')) }.to raise_error(Puppet::Error, /Recurring day must be one of/)
    end

    specify 'should not accept start_time' do
      expect { described_class.new(defaults.merge(:reoccurrence => :weekly, :start_time => '00:00')) }.to raise_error(Puppet::Error, /start_time not allowed/)
    end

    specify 'should not accept cron_expression' do
      expect { described_class.new(defaults.merge(:reoccurrence => :weekly, :cron_expression => '0 0 12 * * ?')) }.to raise_error(Puppet::Error, /cron_expression not allowed/)
    end
  end


  describe 'reoccurrence monthly' do
    specify 'should accept valid input' do
      expect { described_class.new(defaults.merge(:reoccurrence => :monthly, :start_date => '1970-01-01', :recurring_day => 'last', :recurring_time => '23:59')) }.to_not raise_error
    end

    specify 'should accept recurring_day as day of month' do
      expect { described_class.new(defaults.merge(:reoccurrence => :monthly, :start_date => '1970-01-01', :recurring_day => [1, 2, 30, 31], :recurring_time => '23:59')) }.to_not raise_error
    end

    specify 'should not accept missing start_date' do
      expect { described_class.new(defaults.merge(:reoccurrence => :monthly, :recurring_day => 'last', :recurring_time => '00:00')) }.to raise_error(Puppet::Error, /requires start_date/)
    end

    specify 'should not accept missing recurring_day' do
      expect { described_class.new(defaults.merge(:reoccurrence => :monthly, :start_date => '1970-01-01', :recurring_time => '00:00')) }.to raise_error(Puppet::Error, /requires recurring_day/)
    end

    specify 'should not accept recurring_day as weekday' do
      expect { described_class.new(defaults.merge(:reoccurrence => :monthly, :start_date => '1970-01-01', :recurring_day => 'monday', :recurring_time => '00:00')) }.to raise_error(Puppet::Error, /Recurring day must be one of/)
    end

    specify 'should not accept missing recurring_time' do
      expect { described_class.new(defaults.merge(:reoccurrence => :monthly, :start_date => '1970-01-01', :recurring_day => 'last')) }.to raise_error(Puppet::Error, /requires recurring_time/)
    end

    specify 'should not accept missing start_date, recurring_day and reccuring_time' do
      expect { described_class.new(defaults.merge(:reoccurrence => :monthly)) }.to raise_error(Puppet::Error, /requires start_date and recurring_day and recurring_time/)
    end

    specify 'should not accept start_time' do
      expect { described_class.new(defaults.merge(:reoccurrence => :monthly, :start_time => '00:00')) }.to raise_error(Puppet::Error, /start_time not allowed/)
    end

    specify 'should not accept cron_expression' do
      expect { described_class.new(defaults.merge(:reoccurrence => :monthly, :cron_expression => '0 0 12 * * ?')) }.to raise_error(Puppet::Error, /cron_expression not allowed/)
    end
  end

  describe 'reoccurrence advanced' do
    specify 'should accept valid input' do
      expect { described_class.new(defaults.merge(:reoccurrence => :advanced, :cron_expression => '0 0 12 * * ?')) }.to_not raise_error
    end

    specify 'should not accept missing cron_expression' do
      expect { described_class.new(defaults.merge(:reoccurrence => :advanced)) }.to raise_error(Puppet::Error, /requires cron_expression/)
    end

    specify 'should not accept start_date' do
      expect { described_class.new(defaults.merge(:reoccurrence => :advanced, :start_date => '2014-06-01')) }.to raise_error(Puppet::Error, /start_date not allowed/)
    end

    specify 'should not accept start_time' do
      expect { described_class.new(defaults.merge(:reoccurrence => :advanced, :start_time => '00:00')) }.to raise_error(Puppet::Error, /start_time not allowed/)
    end

    specify 'should not accept recurring_day' do
      expect { described_class.new(defaults.merge(:reoccurrence => :advanced, :recurring_day => 'monday')) }.to raise_error(Puppet::Error, /recurring_day not allowed/)
    end

    specify 'should not accept recurring_time' do
      expect { described_class.new(defaults.merge(:reoccurrence => :advanced, :recurring_time => '00:00')) }.to raise_error(Puppet::Error, /recurring_time not allowed/)
    end
  end

  describe :cron_expression do
    specify 'should not accept empty value' do
      expect { described_class.new(advanced.merge(:cron_expression => '')) }.to raise_error(Puppet::Error, /Cron expression must be a non-empty string/)
    end

    specify 'should accept regular cron expression' do
      expect { described_class.new(advanced.merge(:cron_expression => '0 0 12 * * ?')) }.to_not raise_error
    end
  end

  describe :start_date do
    specify 'should default to nil' do
      expect(described_class.new(defaults)[:start_date]).to be_nil
    end

    specify 'should accept epoch' do
      expect { described_class.new(once.merge(:start_date => '1970-01-01')) }.to_not raise_error
    end

    specify 'should accept valid date' do
      expect { described_class.new(once.merge(:start_date => '2014-06-15')) }.to_not raise_error
    end

    specify 'should not accept empty strings' do
      expect { described_class.new(once.merge(:start_date => '')) }.to raise_error(Puppet::Error, /must not be empty/)
    end

    specify 'should not accept characters' do
      expect { described_class.new(once.merge(:start_date => 'invalid')) }.to raise_error(Puppet::Error, /must match YYYY-MM-DD/)
    end

    specify 'should not accept numeric values' do
      expect { described_class.new(once.merge(:start_date => 1)) }.to raise_error(Puppet::Error, /must match YYYY-MM-DD/)
    end
  end

  describe :start_time do
    specify 'should default to nil' do
      expect(described_class.new(defaults)[:start_time]).to be_nil
    end

    specify 'should not accept empty value' do
      expect { described_class.new(once.merge(:start_time => '')) }.to raise_error(Puppet::Error, /must match the following format:/)
    end

    specify 'should accept valid time' do
      expect { described_class.new(once.merge(:start_time => '1:23')) }.to_not raise_error
    end

    specify 'should accept all zeros' do
      expect { described_class.new(once.merge(:start_time => '00:00')) }.to_not raise_error
    end
  end

  describe :recurring_time do
    specify 'should default to nil' do
      expect(described_class.new(defaults)[:recurring_time]).to be_nil
    end

    specify 'should not accept empty value' do
      expect { described_class.new(weekly.merge(:recurring_time => '')) }.to raise_error(Puppet::Error, /must match the following format:/)
    end

    specify 'should accept valid time' do
      expect { described_class.new(weekly.merge(:recurring_time => '1:23')) }.to_not raise_error
    end

    specify 'should accept all zeros' do
      expect { described_class.new(weekly.merge(:recurring_time => '00:00')) }.to_not raise_error
    end
  end

  describe :recurring_day do
    specify 'should default to nil' do
      expect(described_class.new(defaults)[:recurring_day]).to be_nil
    end

    specify 'should munge day of week to lowercase' do
      expect(described_class.new(weekly.merge(:recurring_day => 'MONDAY'))[:recurring_day]).to eq('monday')
    end

    specify 'should not accept empty value' do
      expect { described_class.new(weekly.merge(:recurring_day => '')) }.to raise_error(Puppet::Error, /must not be empty/)
    end

    specify 'should not accept a comma-separated string' do
      expect { described_class.new(weekly.merge(:recurring_day => '1,2')) }.to raise_error(Puppet::Error, /must be provided as an array/)
    end

    specify 'should accept valid weekday' do
      expect { described_class.new(weekly.merge(:recurring_day => 'saturday')) }.to_not raise_error
    end

    specify 'should accept day as integer' do
      expect { described_class.new(monthly.merge(:recurring_day => 1)) }.to_not raise_error
    end

    specify 'should accept day as string' do
      expect { described_class.new(monthly.merge(:recurring_day => '1')) }.to_not raise_error
    end

    specify 'should accept last day' do
      expect { described_class.new(monthly.merge(:recurring_day => 'last')) }.to_not raise_error
    end

    specify 'should accept multiple values' do
      expect { described_class.new(monthly.merge(:recurring_day => ['1', 'last'])) }.to_not raise_error
    end
  end
end
