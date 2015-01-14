require 'puppet_x/nexus/scheduled_tasks'
require 'spec_helper'

describe Nexus::StagingRuleset do

  describe :find_type_by_id do
    specify { expect(described_class.find_type_by_id('uniq-staging').name).to eq('Artifact Uniqueness Validation') }
    specify { expect(described_class.find_type_by_id('uniq-staging'.intern).name).to eq('Artifact Uniqueness Validation') }
    specify { expect(described_class.find_type_by_id('unknown').name).to eq('unknown') }
  end

  describe :find_type_by_name do
    specify { expect(described_class.find_type_by_name('Artifact Uniqueness Validation').id).to eq('uniq-staging') }
    specify { expect(described_class.find_type_by_name('Artifact Uniqueness Validation'.intern).id).to eq('uniq-staging') }
    specify { expect(described_class.find_type_by_name('unknown').id).to eq('unknown') }
  end
end
