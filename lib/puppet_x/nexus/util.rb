module Nexus
  class Util

    def self.strip_hash(hash)
      hash.each do |key, value|
        self.strip_hash(value) if value.is_a?(Hash)
        hash.delete(key) if ((value.respond_to?(:empty?) && value.empty?) || value.nil?)
      end
    end

    def self.sym_to_bool(sym)
      nil == sym ? nil : :true == sym
    end

    # See #a_boolean_or_default
    #
    def self.a_boolean_or_absent(value)
      a_boolean_or_default(value, :absent)
    end

    # Returns the given value as a symbol if it is a boolean `true` or `false` or the default value otherwise
    #
    def self.a_boolean_or_default(value, default)
      value.nil? ? default : value.to_s.intern
    end

    # See #a_list_or_default
    #
    def self.a_list_or_absent(value)
      a_list_or_default(value, :absent)
    end

    # Returns the given value in a format as expected by the Puppet::Property::List class (that is a string joined by a
    # comma) or the default value otherwise.
    #
    def self.a_list_or_default(value, default)
      value.nil? ? default : value.join(',')
    end
  end
end
