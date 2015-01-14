require 'spec_helper'

describe Puppet::Type.type(:nexus_staging_ruleset).provider(:ruby) do
  let(:example_data) do
    {
        'id'          => '1',
        'name'        => 'Example rule set',
        'description' => 'This could be a long description.',
        'rules'       => [
            {
                'name'       => 'Artifact Uniqueness Validation',
                'typeId'     => 'uniq-staging',
                'typeName'   => 'Artifact Uniqueness Validation',
                'enabled'    => true,
                'properties' => []
            },
            {
                'name'       => 'Javadoc Validation',
                'typeId'     => 'javadoc-staging',
                'typeName'   => 'Javadoc Validation',
                'enabled'    => true,
                'properties' => []
            },
            {
                'name'       => 'POM Validation',
                'typeId'     => 'pom-staging',
                'typeName'   => 'POM Validation',
                'enabled'    => false,
                'properties' => []
    }        ]
    }
  end

  let(:resource) do
    {
        :name        => 'Some Rule',
        :description => 'Just a simple staging rule set.',
        :rules       => [
            'Artifact Uniqueness Validation',
            'Javadoc Validation',
        ]
    }
  end

  let(:instance) do
    described_class.new(Puppet::Type::Nexus_staging_ruleset.new(resource))
  end

  before(:each) do
    Nexus::Config.stub(:resolve).and_return('http://example.com/foobar')
    Nexus::Rest.stub(:get_all).and_return({'data' => {'otherdata' => 'foobar'}})
  end

  describe :instances do
    specify do
      Nexus::Rest.should_receive(:get_all).with('/service/local/staging/rule_sets').and_return(
          {
              'data' => [
                  {
                      'id'    => '1',
                      'name'  => 'ruleset 1',
                      'rules' => [
                          {
                            'typeId'  => 'uniq-staging',
                            'enabled' => true
                          }
                      ]
                  },
                  {
                      'id'    => '2',
                      'name'  => 'ruleset 2',
                      'rules' => [
                          {
                              'typeId'  => 'pom-staging',
                              'enabled' => true
                          }
                      ]
                  }
              ]
          }
      )

      expect(described_class.instances).to have(2).items
    end

    specify do
      Nexus::Rest.should_receive(:get_all).and_raise('Operation failed')

      expect { described_class.instances }.to raise_error(Puppet::Error, /Error while retrieving all nexus_staging_ruleset instances/)
    end

    specify 'should set ensure to present' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data]})

      expect(described_class.instances[0].ensure).to eq(:present)
    end

    specify 'should retrieve id' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data]})

      expect(described_class.instances[0].id).to eq('1')
    end

    specify 'should retrieve name' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data]})

      expect(described_class.instances[0].name).to eq('Example rule set')
    end

    specify 'should retrieve description' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data]})

      expect(described_class.instances[0].description).to eq('This could be a long description.')
    end

    specify 'should map typeId of the rule to type' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data]})

      expect(described_class.instances[0].rules).to include('Artifact Uniqueness Validation')
    end

    specify 'should join rules into a single string' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data]})

      expect(described_class.instances[0].rules).to eq('Artifact Uniqueness Validation,Javadoc Validation')
    end

    specify 'should ignore rules with enabled => false' do
      Nexus::Rest.should_receive(:get_all).and_return({'data' => [example_data]})

      expect(described_class.instances[0].rules).to_not include('POM Validation')
    end
  end

  describe :create do
    specify 'should use /service/local/staging/rule_sets to create a new resource' do
      Nexus::Rest.should_receive(:create).with('/service/local/staging/rule_sets', anything())

      expect { instance.create }.to_not raise_error
    end

    specify 'should raise a human readable error message if the operation failed' do
      Nexus::Rest.should_receive(:create).and_raise('Operation failed')

      expect { instance.create }.to raise_error(Puppet::Error, /Error while creating nexus_staging_ruleset\['Some Rule'\]/)
    end
  end

  describe :map_resource_to_data do
    specify 'should return all changes within data hash' do
      expect(instance.map_resource_to_data.keys).to eq(['data'])
    end

    specify do
      expect(instance.map_resource_to_data['data']).to_not include('id')
    end

    specify do
      instance.set({:id => 'a1b2'})

      expect(instance.map_resource_to_data['data']).to include('id' => 'a1b2')
    end

    specify do
      resource[:name] = 'Example rule set'

      expect(instance.map_resource_to_data['data']).to include('name' => 'Example rule set')
    end

    specify do
      resource[:description] = 'This could be a long description.'

      expect(instance.map_resource_to_data['data']).to include('description' => 'This could be a long description.')
    end

    specify do
      resource[:rules] = [
          'Artifact Uniqueness Validation',
          'Javadoc Validation'
      ]

      expect(instance.map_resource_to_data['data']).to include('rules')
      expect(instance.map_resource_to_data['data']['rules']).to have(2).items
    end

    specify 'should add a rule name' do
      resource[:rules] = 'Artifact Uniqueness Validation'

      expect(instance.map_resource_to_data['data']['rules'][0]).to include('name' => 'Artifact Uniqueness Validation')
    end

    specify 'should add a rule typeId' do
      resource[:rules] = 'Artifact Uniqueness Validation'

      expect(instance.map_resource_to_data['data']['rules'][0]).to include('typeId' => 'uniq-staging')
    end

    specify 'should enable rule' do
      resource[:rules] = 'Artifact Uniqueness Validation'

      expect(instance.map_resource_to_data['data']['rules'][0]).to include('enabled' => true)
    end
  end

  describe :flush do
    specify 'should use /service/local/staging/rule_sets<id> to update an existing resource' do
      instance.set({:id => 'a1b2'})
      instance.mark_config_dirty
      Nexus::Rest.should_receive(:update).with('/service/local/staging/rule_sets/a1b2', anything())

      expect { instance.flush }.to_not raise_error
    end

    specify 'should raise a human readable error message if the operation failed' do
      instance.mark_config_dirty
      Nexus::Rest.should_receive(:update).and_raise('Operation failed')

      expect { instance.flush }.to raise_error(Puppet::Error, /Error while updating nexus_staging_ruleset\['Some Rule'\]/)
    end
  end

  describe :destroy do
    specify 'should use /service/local/staging/rule_sets to delete an existing resource' do
      instance.set({:id => 'a1b2'})
      Nexus::Rest.should_receive(:destroy).with('/service/local/staging/rule_sets/a1b2')

      expect { instance.destroy }.to_not raise_error
    end

    specify 'should raise a human readable error message if the operation failed' do
      Nexus::Rest.should_receive(:destroy).and_raise('Operation failed')

      expect { instance.destroy }.to raise_error(Puppet::Error, /Error while deleting nexus_staging_ruleset\['Some Rule'\]/)
    end
  end
end
