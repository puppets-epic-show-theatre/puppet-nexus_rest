require 'puppet_x/nexus/scheduled_tasks'
require 'spec_helper'

describe Nexus::ScheduledTasks do

  describe :find_type_by_id do
    specify { expect(described_class.find_type_by_id('EmptyTrashTask').name).to eq('Empty Trash') }
    specify { expect(described_class.find_type_by_id(:EmptyTrashTask).name).to eq('Empty Trash') }
    specify { expect(described_class.find_type_by_id('unknown').name).to eq('unknown') }
  end

  describe :find_type_by_name do
    specify { expect(described_class.find_type_by_name('Empty Trash').id).to eq('EmptyTrashTask') }
    specify { expect(described_class.find_type_by_name('Empty Trash'.intern).id).to eq('EmptyTrashTask') }
    specify { expect(described_class.find_type_by_name('unknown').id).to eq('unknown') }
  end
end
