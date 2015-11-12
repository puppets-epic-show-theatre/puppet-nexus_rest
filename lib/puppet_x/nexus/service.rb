require 'json'

module Nexus

  # Ensures the referenced Nexus instance is up and running. It does the health check only once and caches the result.
  #
  class CachingService

    # delegatee - the actual Nexus::Service to be used to do the health checking
    #
    def initialize(delegatee)
      @delegatee = delegatee
    end

    # See Nexus::Service.ensure_running.
    #
    def ensure_running
      if @last_result == :not_running
        fail("Nexus service failed a previous health check.")
      else
        begin
          @delegatee.ensure_running
          @last_result = :running
        rescue => e
          @last_result = :not_running
          raise e
        end
      end
    end
  end

  class Service

    def initialize(client, configuration)
      @client = client
      @retries = configuration[:health_check_retries]
      @timeout = configuration[:health_check_timeout]
    end

    # Ensures the referenced Nexus instance is up and running.
    #
    # If the service is down or cannot be reached for some reason, the method will wait up to the configured limit.
    # If the retry limit has been reached, the method will raise an exception.
    #
    def ensure_running
      for i in 1..@retries do
        result = @client.check_health
        case result.status
          when :not_running
            Puppet.debug("%s Waiting #{@timeout} seconds before trying again." % result.log_message)
            sleep(@timeout)
          when :running
              Puppet.debug("Nexus service is running.")
            return
          when :broken
            fail(result.log_message)
          else
        end
      end
      fail("Nexus service did not start up within #{@timeout * @retries} seconds. You should check the Nexus log " +
        "files to see if something is wrong or consider increasing the timeout if the service is not starting up in " +
        "time.")
    end

    class Status
      attr_reader :status, :log_message

      def initialize(status, log_message)
        @status = status
        @log_message = log_message
      end

      # Service is still starting up ...
      #
      def self.not_running(log_message)
        Status.new(:not_running, log_message)
      end

      # Service is running.
      #
      def self.running
        Status.new(:running, '')
      end

      # Service failed to start up and and will not recover by waiting any longer.
      #
      def self.broken(log_message)
        Status.new(:broken, log_message)
      end
    end

    # Talks to the service in order to find out about the current health of the service.
    #
    class HealthCheckClient

      NOT_RUNNING_MSG = 'Nexus service is not running, yet. Last reported status is: %s'
      CONFIGURATION_BROKEN_MSG = 'Nexus service reached state %s from which it cannot recover from without user intervention. Reported error is: %s.'

      def initialize(configuration)
        @nexus = RestClient::Resource.new(
          configuration[:nexus_base_url],
          :user         => configuration[:admin_username],
          :password     => configuration[:admin_password],
          :timeout      => configuration[:connection_timeout],
          :open_timeout => configuration[:connection_open_timeout]
        )
      end

      # Returns the health status of the service.
      #
      def check_health
        begin
          response = @nexus['/service/local/status'].get(:accept => :json)
          data = JSON.parse(response).fetch('data', [])
          current_state = data.fetch('state', '')
          error_cause = data.fetch('errorCause', '')

          status = case current_state.intern
            # see https://github.com/sonatype/nexus-oss/blob/master/components/nexus-core/src/main/java/org/sonatype/nexus/SystemState.java
            # for a list of all available states
            #
            when :STARTED then Service::Status.running
            when :BROKEN_IO, :BROKEN_CONFIGURATION then Service::Status.broken(CONFIGURATION_BROKEN_MSG % [current_state, error_cause])
            else Service::Status.not_running(NOT_RUNNING_MSG % current_state)
          end
        rescue => e
          return Service::Status.not_running("Caught an exception while checking status of Nexus service: #{e}.")
        end
      end
    end

  end
end
