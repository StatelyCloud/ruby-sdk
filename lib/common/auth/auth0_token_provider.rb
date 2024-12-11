# frozen_string_literal: true

require "async"
require "async/actor"
require "async/http/internet"
require "async/semaphore"
require "json"
require "logger"
require "weakref"
require_relative "token_provider"

LOGGER = Logger.new($stdout)
LOGGER.level = Logger::WARN
DEFAULT_GRANT_TYPE = "client_credentials"

# A module for Stately Cloud auth code
module StatelyDB
  module Common
    # A module for Stately Cloud auth code
    module Auth
      # Auth0TokenProvider is an implementation of the TokenProvider abstract base class
      # which vends tokens from auth0 with the given client_id and client_secret.
      # It will default to using the values of `STATELY_CLIENT_ID` and `STATELY_CLIENT_SECRET` if
      # no credentials are explicitly passed and will throw an error if none are found.
      class Auth0TokenProvider < TokenProvider
        # @param [String] origin The origin of the OAuth server
        # @param [String] audience The OAuth Audience for the token
        # @param [String] client_secret The StatelyDB client secret credential
        # @param [String] client_id The StatelyDB client ID credential
        def initialize(
          origin: "https://oauth.stately.cloud",
          audience: "api.stately.cloud",
          client_secret: ENV.fetch("STATELY_CLIENT_SECRET"),
          client_id: ENV.fetch("STATELY_CLIENT_ID")
        )
          super()
          @actor = Async::Actor.new(Actor.new(origin: origin, audience: audience,
                                              client_secret: client_secret, client_id: client_id))
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
          # @param [String] origin The origin of the OAuth server
          # @param [String] audience The OAuth Audience for the token
          # @param [String] client_secret The StatelyDB client secret credential
          # @param [String] client_id The StatelyDB client ID credential
          def initialize(
            origin:,
            audience:,
            client_secret:,
            client_id:
          )
            super()
            @client = Async::HTTP::Client.new(Async::HTTP::Endpoint.parse(origin))
            @client_id = client_id
            @client_secret = client_secret
            @audience = audience

            @access_token = nil
            @expires_at_unix_secs = nil
            @pending_refresh = nil
          end

          # Initialize the actor. This runs on the actor thread which means
          # we can dispatch async operations here.
          def init
            refresh_token
          end

          # Close the token provider and kill any background operations
          def close
            @scheduled&.stop
            @client&.close
          end

          # Get the current access token
          # @param [Boolean] force Whether to force a refresh of the token
          # @return [String] The current access token
          def get_token(force: false)
            if force
              @access_token = nil
              @expires_at_unix_secs = nil
            else
              token, ok = valid_access_token
              return token if ok
            end

            refresh_token.wait
          end

          # Get the current access token and whether it is valid
          # @return [Array] The current access token and whether it is valid
          def valid_access_token
            return "", false if @access_token.nil?
            return "", false if @expires_at_unix_secs.nil?
            return "", false if @expires_at_unix_secs < Time.now.to_i

            [@access_token, true]
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
              resp_data = make_auth0_request

              new_access_token = resp_data["access_token"]
              new_expires_in_secs = resp_data["expires_in"]
              new_expires_at_unix_secs = Time.now.to_i + new_expires_in_secs
              if @expires_at_unix_secs.nil? || new_expires_at_unix_secs > @expires_at_unix_secs

                @access_token = new_access_token
                @expires_at_unix_secs = new_expires_at_unix_secs
              else

                new_access_token = @access_token
                new_expires_in_secs = @expires_at_unix_secs - Time.now.to_i
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

              new_access_token
            end
          end

          def make_auth0_request
            headers = [["content-type", "application/json"]]
            body = JSON.dump({ "client_id" => @client_id, client_secret: @client_secret, audience: @audience,
                               grant_type: DEFAULT_GRANT_TYPE })
            Sync do
              # TODO: Wrap this in a retry loop and parse errors like we
              # do in the Go SDK.
              response = @client.post("/oauth/token", headers, body)
              raise "Auth request failed" if response.status != 200

              JSON.parse(response.read)
            ensure
              response&.close
            end
          end
        end
      end
    end
  end
end
