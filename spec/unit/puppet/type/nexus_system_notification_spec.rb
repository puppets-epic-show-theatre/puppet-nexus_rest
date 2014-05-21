require 'spec_helper'

describe Puppet::Type.type(:nexus_system_notification) do
  let(:notification) { described_class.new(:name => 'any') }
  specify 'by default' do
    expect(notification[:enabled]).to be_false
    expect(notification[:emails]).to be_nil
  end

  describe 'emails' do
    specify 'should accept a single string' do
      expect {
        described_class.new(:name => 'any', :emails => 'jdoe@example.com')
      }.to_not raise_error
    end

    specify 'should accept an empty string' do
      expect {
        described_class.new(:name => 'any', :emails => '')
      }.to_not raise_error
    end

    specify 'should accept an empty array' do
      expect {
        described_class.new(:name => 'any', :emails => [])
      }.to_not raise_error
    end

    specify 'should accept multiple elements' do
      expect {
        described_class.new(:name => 'any', :emails => ['jdoe@example.com'])
      }.to_not raise_error
      expect {
        described_class.new(:name => 'any', :emails => ['john@example.com', 'jane@example.com'])
      }.to_not raise_error
    end

    specify 'should not accept invalid email addresses' do
      expect {
        described_class.new(:name => 'any', :emails => ['fail'])
      }.to raise_error(Puppet::ResourceError, /Invalid email address 'fail'/)
    end
  end

  describe 'roles' do
    specify 'should accept a single string' do
      expect {
        described_class.new(:name => 'any', :roles => 'admins')
      }.to_not raise_error
    end

    specify 'should accept an empty string' do
      expect {
        described_class.new(:name => 'any', :roles => '')
      }.to_not raise_error
    end

    specify 'should accept an empty array' do
      expect {
        described_class.new(:name => 'any', :roles => [])
      }.to_not raise_error
    end

    specify 'should accept multiple elements' do
      expect {
        described_class.new(:name => 'any', :roles => ['admins'])
      }.to_not raise_error
      expect {
        described_class.new(:name => 'any', :roles => ['admins', 'users'])
      }.to_not raise_error
    end
  end
end
