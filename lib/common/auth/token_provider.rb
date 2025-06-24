# frozen_string_literal: true

module StatelyDB
  module Common
    # A module for Stately Cloud auth code
    module Auth
      # TokenProvider is an abstract base class that should be extended
      # for individual token provider implementations
      class TokenProvider
        # Start the token provider. Starting multiple times should be a no-op.
        # @param [String] endpoint The endpoint to connect to
        # @return [void]
        def start(endpoint: "https://api.stately.cloud") # rubocop:disable Lint/UnusedMethodArgument
          raise "Not Implemented"
        end

        # Get the current access token
        # @param [Boolean] force Whether to force a refresh of the token
        # @return [String] The current access token
        def get_token(force: false) # rubocop:disable Lint/UnusedMethodArgument
          raise "Not Implemented"
        end

        # Close the token provider and kill any background operations
        # @return [void]
        def close
          raise "Not Implemented"
        end
      end
    end
  end
end
