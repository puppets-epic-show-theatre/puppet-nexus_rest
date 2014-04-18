require 'json'

module Nexus
  class ExceptionHandler
    def self.process(e)
      msg = e.to_s
      msg += ', details: ' + retrieve_error_message(e.http_body) if e.methods.include? :http_body
      yield msg
    end

    def self.retrieve_error_message(data)
      if data.nil? || data.empty?
        return 'unknown'
      elsif (data.is_a? String) && data.include?('<html>')
        return data.match(/<p>(.*)<\/p>/)[1]
      end

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
      elsif json[:errors]
        json[:errors].collect {|entry| entry[:msg] }.join(' ')
      else
        'unknown'
      end
    end
  end
end