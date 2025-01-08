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

      # StatelyAccessTokenFetcher is a TokenFetcher that fetches tokens from the StatelyDB API
      class StatelyAccessTokenFetcher < TokenFetcher
        NON_RETRYABLE_ERRORS = [
          GRPC::Core::StatusCodes::UNAUTHENTICATED,
          GRPC::Core::StatusCodes::PERMISSION_DENIED,
          GRPC::Core::StatusCodes::NOT_FOUND,
          GRPC::Core::StatusCodes::UNIMPLEMENTED,
          GRPC::Core::StatusCodes::INVALID_ARGUMENT
        ].freeze
        RETRY_ATTEMPTS = 10

        # @param [String] endpoint The endpoint of the OAuth server
        # @param [String] access_key The StatelyDB access key credential
        # @param [Float] base_retry_backoff_secs The base backoff time in seconds
        def initialize(endpoint:, access_key:, base_retry_backoff_secs:)
          super()
          @access_key = access_key
          @base_retry_backoff_secs = base_retry_backoff_secs
          @channel = Common::Net.new_channel(endpoint:)
          error_interceptor = Common::ErrorInterceptor.new
          @stub = Stately::Auth::AuthService::Stub.new(nil, nil, channel_override: @channel,
                                                                 interceptors: [error_interceptor])
        end

        # Fetch a new token from the StatelyDB API
        # @return [TokenResult] The fetched TokenResult
        def fetch
          RETRY_ATTEMPTS.times do |i|
            resp = @stub.get_auth_token(Stately::Auth::GetAuthTokenRequest.new(access_key: @access_key))
            return TokenResult.new(token: resp.auth_token, expires_in_secs: resp.expires_in_s)
          rescue StatelyDB::Error => e
            # raise if it's the final attempt or if the error is not retryable
            raise e unless self.class.retryable_error?(e) && i < RETRY_ATTEMPTS - 1

            # exponential backoff
            sleep(backoff(i, @base_retry_backoff_secs))
          end
        end

        def close
          @channel&.close
        end

        # Check if an error is retryable
        # @param [StatelyDB::Error] err The error to check
        # @return [Boolean] True if the error is retryable
        def self.retryable_error?(err)
          !NON_RETRYABLE_ERRORS.include?(err.code)
        end
      end
    end
  end
end

# backoff returns a duration to wait before retrying a request. `attempt` is
# the current attempt number, starting from 0 (e.g. the first attempt is 0,
# then 1, then 2...).
#
# @param [Integer] attempt The current attempt number
# @param [Float] base_backoff The base backoff time in seconds
# @return [Float] The duration in seconds to wait before retrying
def backoff(attempt, base_backoff)
  # Double the base backoff time per attempt, starting with 1
  exp = 2**attempt
  # Add a full jitter to the backoff time, from no wait to 100% of the exponential backoff.
  # See https://aws.amazon.com/blogs/architecture/exponential-backoff-and-jitter/
  jitter = rand
  (exp * jitter * base_backoff)
end
