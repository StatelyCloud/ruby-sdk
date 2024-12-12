# frozen_string_literal: true

require_relative "../net/conn"
require_relative "../error_interceptor"
require_relative "../../api/auth/service_services_pb"
require "grpc"

module StatelyDB
  module Common
    # A module for Stately Cloud auth code
    module Auth
      # Result from a token fetch operation
      class TokenResult
        attr_reader :token, :expires_in_secs

        # Create a new TokenResult
        # @param [String] token The access token
        # @param [Integer] expires_in_secs The number of seconds until the token expires
        def initialize(token:, expires_in_secs:)
          @token = token
          @expires_in_secs = expires_in_secs
        end
      end

      # TokenFetcher is an abstract base class that should be extended
      # for individual token fetcher implementations
      class TokenFetcher
        # Get the current access token
        # @return [TokenResult] The fetched TokenResult
        def fetch
          raise "Not Implemented"
        end

        # Close the token provider and kill any background operations
        def close
          raise "Not Implemented"
        end
      end

      # Auth0TokenFetcher is a TokenFetcher that fetches tokens from an Auth0 server
      class Auth0TokenFetcher < TokenFetcher
        # @param [String] origin The origin of the OAuth server
        # @param [String] audience The OAuth Audience for the token
        # @param [String] client_secret The StatelyDB client secret credential
        # @param [String] client_id The StatelyDB client ID credential
        def initialize(origin:, audience:, client_secret:, client_id:)
          super()
          @client = Async::HTTP::Client.new(Async::HTTP::Endpoint.parse(origin))
          @audience = audience
          @client_secret = client_secret
          @client_id = client_id
        end

        # Fetch a new token from auth0
        # @return [TokenResult] The fetched TokenResult
        def fetch
          headers = [["content-type", "application/json"]]
          body = JSON.dump({ "client_id" => @client_id, client_secret: @client_secret, audience: @audience,
                             grant_type: DEFAULT_GRANT_TYPE })
          Sync do
            # TODO: Wrap this in a retry loop and parse errors like we
            # do in the Go SDK.
            response = @client.post("/oauth/token", headers, body)
            raise "Auth request failed" if response.status != 200

            resp_data = JSON.parse(response.read)
            TokenResult.new(token: resp_data["access_token"], expires_in_secs: resp_data["expires_in"])
          ensure
            response&.close
          end
        end

        def close
          @client&.close
        end
      end

      # StatelyAccessTokenFetcher is a TokenFetcher that fetches tokens from the StatelyDB API
      class StatelyAccessTokenFetcher < TokenFetcher
        # @param [String] origin The origin of the OAuth server
        # @param [String] access_key The StatelyDB access key credential
        def initialize(origin:, access_key:)
          super()
          @access_key = access_key
          @channel = Common::Net.new_channel(endpoint: origin)
          error_interceptor = Common::ErrorInterceptor.new
          @stub = Stately::Auth::AuthService::Stub.new(nil, nil, channel_override: @channel,
                                                                 interceptors: [error_interceptor])
        end

        # Fetch a new token from the StatelyDB API
        # @return [TokenResult] The fetched TokenResult
        def fetch
          resp = @stub.get_auth_token(Stately::Auth::GetAuthTokenRequest.new(access_key: @access_key))
          TokenResult.new(token: resp.auth_token, expires_in_secs: resp.expires_in_s)
        end

        def close
          @channel&.close
        end
      end
    end
  end
end
