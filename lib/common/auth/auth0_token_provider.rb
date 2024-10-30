# frozen_string_literal: true

require "async"
require "async/http/internet"
require "async/semaphore"
require "json"
require "logger"
require "weakref"
require_relative "token_provider"

LOGGER = Logger.new($stdout)
LOGGER.level = Logger::WARN
DEFAULT_GRANT_TYPE = "client_credentials"

module StatelyDB
  module Common
    # A module for Stately Cloud auth code
    module Auth
      # Auth0TokenProvider is an implementation of the TokenProvider abstract base class
      # which vends tokens from auth0 with the given client_id and client_secret.
      # It will default to using the values of `STATELY_CLIENT_ID` and `STATELY_CLIENT_SECRET` if
      # no credentials are explicitly passed and will throw an error if none are found.
      class Auth0TokenProvider < TokenProvider
        # @param [String] auth_url The URL of the OAuth server
        # @param [String] audience The OAuth Audience for the token
        # @param [String] client_secret The StatelyDB client secret credential
        # @param [String] client_id The StatelyDB client ID credential
        def initialize(
          auth_url: "https://oauth.stately.cloud",
          audience: "api.stately.cloud",
          client_secret: ENV.fetch("STATELY_CLIENT_SECRET"),
          client_id: ENV.fetch("STATELY_CLIENT_ID")
        )
          super()
          @client_id = client_id
          @client_secret = client_secret
          @audience = audience
          @auth_url = "#{auth_url}/oauth/token"
          @access_token = nil
          @pending_refresh = nil
          @timer = nil

          Async do |_task|
            refresh_token
          end

          # need a weak ref to ourself or the GC will never run the finalizer
          ObjectSpace.define_finalizer(WeakRef.new(self), finalize)
        end

        # finalizer kills the thread running the timer if one exists
        # @return [Proc] The finalizer proc
        def finalize
          proc {
            Thread.kill(@timer) unless @timer.nil?
          }
        end

        # Get the current access token
        # @return [String] The current access token
        def access_token
          # TODO: - check whether or not the GIL is enough to make this threadsafe
          @access_token || refresh_token
        end

        private

        # Refresh the access token
        # @return [void]
        def refresh_token
          # never run more than one at a time.
          @pending_refresh ||= refresh_token_impl
          # many threads all wait on the same task here.
          # I wrote a test to check this is possible
          @pending_refresh.wait
          # multiple people will all set this to nil after
          # they are done waiting but I don't think i can put this inside
          # refresh_token_impl. It seems harmless because of the GIL?
          @pending_refresh = nil
        end

        # Refresh the access token implementation
        # @return [String] The new access token
        def refresh_token_impl
          Async do
            client = Async::HTTP::Internet.new
            headers = [["content-type", "application/json"]]
            data = { "client_id" => @client_id, client_secret: @client_secret, audience: @audience,
                     grant_type: DEFAULT_GRANT_TYPE }
            body = [JSON.dump(data)]

            resp = client.post(@auth_url, headers, body)
            resp_data = JSON.parse(resp.read)
            raise "Auth request failed: #{resp_data}" if resp.status != 200

            @access_token = resp_data["access_token"]

            # do this on a thread or else the sleep
            # will block the event loop.
            # there is no non-blocking sleep in ruby.
            # skip this if we have a pending timer thread already
            @timer = Thread.new do
              # Calculate a random multiplier between 0.3 and 0.8 to to apply to the expiry
              # so that we refresh in the background ahead of expiration, but avoid
              # multiple processes hammering the service at the same time.
              jitter = (Random.rand * 0.5) + 0.3
              delay = resp_data["expires_in"] * jitter
              sleep(delay)
              refresh_token
            end
            @pending_refresh = nil
            resp_data["access_token"]
          rescue StandardError => e
            # set the token to nil so that it will
            # be refreshed on the next get
            @access_token = nil
            LOGGER.warn(e)
          ensure
            client.close
          end
        end
      end
    end
  end
end
