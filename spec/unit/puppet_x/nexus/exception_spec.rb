require 'spec_helper'

describe Nexus::ExceptionHandler do
  describe 'retrieve_error_message' do
    it { expect(Nexus::ExceptionHandler.retrieve_error_message('')).to eq('unknown') }
    it { expect(Nexus::ExceptionHandler.retrieve_error_message(nil)).to eq('unknown') }
    it { expect(Nexus::ExceptionHandler.retrieve_error_message('\n<html><p>Error</p></html>')).to eq('Error') }
    it { expect(Nexus::ExceptionHandler.retrieve_error_message('\n<html>crap</html>')).to eq('unknown') }
    it { expect(Nexus::ExceptionHandler.retrieve_error_message('{"errors": [{"msg": "Error"}]}')).to eq('Error') }
    it { expect(Nexus::ExceptionHandler.retrieve_error_message({'errors' => [{'msg' => 'Error'}]})).to eq('Error') }
  end
end
