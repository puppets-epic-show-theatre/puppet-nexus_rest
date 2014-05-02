require 'json'

module Nexus
  class ExceptionHandler
    def self.process(e)
      # by default, include exception message
      msg = e.to_s
      msg += ', details: ' + retrieve_error_message(e.http_body) if e.respond_to? :http_body
      yield msg
    end

    def self.retrieve_error_message(data)
      if data.nil? || data.empty?
        return 'unknown'
      # even through we only accept JSON, the REST resource sometimes returns HTML
      elsif (data.is_a? String) && data.include?('<html>')
        error_message = data.match(/<p>(.*)<\/p>/)
        return error_message ? error_message[1]: 'unknown'
      end

      # sometimes the error message is a Hash, sometimes a String; trying to parse the String
      json = data
      if data.is_a? String
        begin
          json = JSON.parse(data)
        rescue
          return 'unknown'
        end
      end
        
      # The data normally looks like
      # {
      #    "errors":
      #    [
      #        {
      #            "id": "*",
      #            "msg": "... <long error message> ..."
      #        }
      #    ]
      # }

      if json['errors']
        json['errors'].collect {|entry| entry['msg'] }.join(' ')
      else
        'unknown'
      end
    end
  end
end