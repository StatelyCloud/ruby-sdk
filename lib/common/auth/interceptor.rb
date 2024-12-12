# frozen_string_literal: true

require "grpc"
require "common/auth/token_provider"

module StatelyDB
  module Common
    # A module for Stately Cloud auth code
    module Auth
      # GRPC interceptor to authenticate against Stately and append bearer tokens to outgoing requests
      class Interceptor < GRPC::ClientInterceptor
        # @param [TokenProvider] token_provider The token provider to use for authentication
        def initialize(
          token_provider: AuthTokenProvider.new
        )
          super()
          @token_provider = token_provider
        end

        # gRPC client unary interceptor
        #
        # @param [Object] request The request object
        # @param [GRPC::ActiveCall] call The active call object
        # @param [Symbol] method The method being called
        # @param [Hash] metadata The metadata hash
        # @return [Object] The response object
        # @api private
        def request_response(request:, call:, method:, metadata:) # rubocop:disable Lint/UnusedMethodArgument
          add_jwt_to_grpc_request(metadata:)
          yield
        end

        # gRPC client streaming interceptor
        #
        # @param [Enumerable] requests The list of requests
        # @param [GRPC::ActiveCall] call The active call object
        # @param [Symbol] method The method being called
        # @param [Hash] metadata The metadata hash
        # @return [Enumerator] The response enumerator
        # @api private
        def client_streamer(requests:, call:, method:, metadata:) # rubocop:disable Lint/UnusedMethodArgument
          add_jwt_to_grpc_request(metadata:)
          yield
        end

        # gRPC  server streaming interceptor
        #
        # @param [Object] request The request object
        # @param [GRPC::ActiveCall] call The active call object
        # @param [Symbol] method The method being called
        # @param [Hash] metadata The metadata hash
        # @return [Enumerator] The response enumerator
        # @api private
        def server_streamer(request:, call:, method:, metadata:) # rubocop:disable Lint/UnusedMethodArgument
          add_jwt_to_grpc_request(metadata:)
          yield
        end

        # gRPC bidirectional streaming interceptor
        #
        # @param [Enumerable] requests The list of requests
        # @param [GRPC::ActiveCall] call The active call object
        # @param [Symbol] method The method being called
        # @param [Hash] metadata The metadata hash
        # @return [Enumerator] The response enumerator
        # @api private
        def bidi_streamer(requests:, call:, method:, metadata:) # rubocop:disable Lint/UnusedMethodArgument
          add_jwt_to_grpc_request(metadata:)
          yield
        end

        # Adds a JWT to the metadata hash
        # @param [Hash] metadata The metadata hash
        # @return [void]
        # @api private
        def add_jwt_to_grpc_request(metadata:)
          metadata["authorization"] = "Bearer #{@token_provider.get_token}"
        end
      end
    end
  end
end
