require 'spec_helper'

describe Puppet::Type.type(:nexus_global_settings) do
  let(:settings) { described_class.new(:name => 'default') }
  specify 'by default' do
    expect(settings[:notification_enabled]).to be_false
    expect(settings[:notification_recipients]).to be_nil
  end

  describe 'notification_recipients' do
    specify 'should accept a single string' do
      expect {
        described_class.new(:name => 'default', :notification_recipients => 'jdoe@example.com')
      }.to_not raise_error
    end

    specify 'should accept an empty string' do
      expect {
        described_class.new(:name => 'default', :notification_recipients => "")
      }.to_not raise_error
    end

    specify 'should accept an empty array' do
      expect {
        described_class.new(:name => 'default', :notification_recipients => [])
      }.to_not raise_error
    end

    specify 'should accept multiple elements' do
      expect {
        described_class.new(:name => 'default', :notification_recipients => ['jdoe@example.com'])
      }.to_not raise_error
      expect {
        described_class.new(:name => 'default', :notification_recipients => ['john@example.com', 'jane@example.com'])
      }.to_not raise_error
    end

    specify 'should not accept invalid email addresses' do
      expect {
        described_class.new(:name => 'default', :notification_recipients => ['fail'])
      }.to raise_error(Puppet::ResourceError, /Invalid email address 'fail'/)
    end
  end
end
