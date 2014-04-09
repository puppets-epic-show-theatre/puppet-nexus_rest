require 'json'
require File.join(File.dirname(__FILE__), '..', 'nexus')

Puppet::Type.type(:nexus_repository).provide(:ruby) do
    desc "Uses Ruby's rest library"

    def self.instances
      repositories = Nexus::Resources.get('/service/local/repositories')
      return repositories['data'].collect do |repository|
        name = repository['id']
        new(:name => name, :ensure => :present)
      end
    end

    def create
      Nexus::Resource.create('/service/local/repositories')
    end

    def update
      Nexus::Resource.update("/service/local/repositories/#{resource[:name]}")
    end

    def destroy
      Nexus::Resource.destroy("/service/local/repositories/#{resource[:name]}")
    end

    def exists?
      @property_hash[:ensure] == :present
    end
end