module Nexus
  class Util

    def strip_hash(hash)
      hash.each do |key, value|
        prune(value) if value.is_a?(Hash)
        hash.delete(key) if ((value.respond_to?(:empty?) && value.empty?) || value.nil?)
      end
    end

  end
end
