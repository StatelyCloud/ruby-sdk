# frozen_string_literal: true

require "async"
require "async/actor"
require "async/http/internet"
require "async/semaphore"
require "json"
require "logger"
require "grpc"
require_relative "token_provider"
require_relative "token_fetcher"
require_relative "../../error"

LOGGER = Logger.new($stdout)
LOGGER.level = Logger::WARN

# A module for Stately Cloud auth code
module StatelyDB
  module Common
    # A module for Stately Cloud auth code
    module Auth
      # AuthTokenProvider is an implementation of the TokenProvider abstract base class
      # which vends tokens from the StatelyDB auth API.
      # It will default to using the value of `STATELY_ACCESS_KEY` if
      # no credentials are explicitly passed and will throw an error if no credentials are found.
      class AuthTokenProvider < TokenProvider
        # @param [String] endpoint The endpoint of the auth server
        # @param [String] access_key The StatelyDB access key credential
        # @param [Float] base_retry_backoff_secs The base retry backoff in seconds
        def initialize(
          endpoint: "https://api.stately.cloud",
          access_key: ENV.fetch("STATELY_ACCESS_KEY", nil),
          base_retry_backoff_secs: 1
        )
          super()
          @actor = Async::Actor.new(Actor.new(endpoint:, access_key:, base_retry_backoff_secs:))
          # this initialization cannot happen in the constructor because it is async and must run on the event loop
          # which is not available in the constructor
          @actor.init
        end

        # Close the token provider and kill any background operations
        # This just invokes the close method on the actor which should do the cleanup
        def close
          @actor.close
        end

        # Get the current access token
        # @return [String] The current access token
        def get_token(force: false)
          @actor.get_token(force: force)
        end

        # Actor for managing the token refresh
        # This is designed to be used with Async::Actor and run on a dedicated thread.
        class Actor
          # @param [String] endpoint The endpoint of the OAuth server
          # @param [String] access_key The StatelyDB access key credential
          # @param [Float] base_retry_backoff_secs The base retry backoff in seconds
          def initialize(endpoint:, access_key:, base_retry_backoff_secs:)
            super()

            if access_key.nil?
              raise StatelyDB::Error.new(
                "Unable to find an access key in the STATELY_ACCESS_KEY " \
                "environment variable. Either pass your credentials in " \
                "the options when creating a client or set this environment variable.",
                code: GRPC::Core::StatusCodes::UNAUTHENTICATED,
                stately_code: "Unauthenticated"
              )
            end

            @token_fetcher = StatelyDB::Common::Auth::StatelyAccessTokenFetcher.new(
              endpoint: endpoint,
              access_key: access_key,
              base_retry_backoff_secs: base_retry_backoff_secs
            )
            @token_state = nil
            @pending_refresh = nil
          end

          # Initialize the actor. This runs on the actor thread which means
          # we can dispatch async operations here.
          def init
            # disable the async lib logger. We do our own error handling and propagation
            Console.logger.disable(Async::Task)
            refresh_token
          end

          # Close the token provider and kill any background operations
          def close
            @scheduled&.stop
            @token_fetcher&.close
          end

          # Get the current access token
          # @param [Boolean] force Whether to force a refresh of the token
          # @return [String] The current access token
          def get_token(force: false)
            if force
              @token_state = nil
            else
              token, ok = valid_access_token
              return token if ok
            end

            refresh_token.wait
          end

          # Get the current access token and whether it is valid
          # @return [Array] The current access token and whether it is valid
          def valid_access_token
            return "", false if @token_state.nil?
            return "", false if @token_state.expires_at_unix_secs < Time.now.to_i

            [@token_state.token, true]
          end

          # Refresh the access token
          # @return [Task] A task that will resolve to the new access token
          def refresh_token
            Async do
              # we use an Async::Condition to dedupe multiple requests here
              # if the condition exists, we wait on it to complete
              # otherwise we create a condition, make the request, then signal the condition with the result
              # If there is an error then we signal that instead so we can raise it for the waiters.
              if @pending_refresh.nil?
                begin
                  @pending_refresh = Async::Condition.new
                  new_access_token = refresh_token_impl
                  # now broadcast the new token to any waiters
                  @pending_refresh.signal(new_access_token)
                  new_access_token
                rescue StandardError => e
                  @pending_refresh.signal(e)
                  raise e
                ensure
                  # delete the condition to restart the process
                  @pending_refresh = nil
                end
              else
                res = @pending_refresh.wait
                # if the refresh result is an error, re-raise it.
                # otherwise return the token
                raise res if res.is_a?(StandardError)

                res
              end
            end
          end

          # Refresh the access token implementation
          # @return [String] The new access token
          def refresh_token_impl
            Sync do
              token_result = @token_fetcher.fetch
              new_expires_in_secs = token_result.expires_in_secs
              new_expires_at_unix_secs = Time.now.to_i + new_expires_in_secs

              # only update the token state if the new expiry is later than the current one
              if @token_state.nil? || new_expires_at_unix_secs > @token_state.expires_at_unix_secs
                @token_state = TokenState.new(token: token_result.token, expires_at_unix_secs: new_expires_at_unix_secs)
              else
                # otherwise use the existing expiry time for scheduling the refresh
                new_expires_in_secs = @token_state.expires_at_unix_secs - Time.now.to_i
              end

              # Schedule a refresh of the token ahead of the expiry time
              # Calculate a random multiplier between 0.9 and 0.95 to to apply to the expiry
              # so that we refresh in the background ahead of expiration, but avoid
              # multiple processes hammering the service at the same time.
              jitter = (Random.rand * 0.05) + 0.9
              delay_secs = new_expires_in_secs * jitter

              # do this on the fiber scheduler (the root scheduler) to avoid infinite recursion
              @scheduled ||= Fiber.scheduler.async do
                # Kernel.sleep is non-blocking if Ruby 3.1+ and Async 2+
                # https://github.com/socketry/async/issues/305#issuecomment-1945188193
                sleep(delay_secs)
                refresh_token
                @scheduled = nil
              end

              @token_state.token
            end
          end
        end

        # Persistent state for the token provider
        class TokenState
          attr_reader :token, :expires_at_unix_secs

          # Create a new TokenState
          # @param [String] token The access token
          # @param [Integer] expires_at_unix_secs The unix timestamp when the token expires
          def initialize(token:, expires_at_unix_secs:)
            @token = token
            @expires_at_unix_secs = expires_at_unix_secs
          end
        end
      end
    end
  end
end
