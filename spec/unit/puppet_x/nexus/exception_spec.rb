require 'puppet_x/nexus/exception'
require 'spec_helper'

describe Nexus::ExceptionHandler do
  describe :retrieve_error_message do
    specify { expect(Nexus::ExceptionHandler.retrieve_error_message('')).to eq('unknown') }
    specify { expect(Nexus::ExceptionHandler.retrieve_error_message(nil)).to eq('unknown') }
    specify { expect(Nexus::ExceptionHandler.retrieve_error_message('\n<html><p>Error</p></html>')).to eq('Error') }
    specify { expect(Nexus::ExceptionHandler.retrieve_error_message('\n<html>crap</html>')).to eq('unknown') }
    specify { expect(Nexus::ExceptionHandler.retrieve_error_message('{"errors": [{"msg": "Error"}]}')).to eq('Error') }
    specify { expect(Nexus::ExceptionHandler.retrieve_error_message({'errors' => [{'msg' => 'Error'}]})).to eq('Error') }
  end
end
