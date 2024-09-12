# frozen_string_literal: true

module StatelyDB
  module Common
    # A module for Stately Cloud auth code
    module Auth
      # TokenProvider is an abstract base class that should be extended
      # for individual token provider implementations
      class TokenProvider
        # Get the current access token
        # @return [String] The current access token
        def access_token
          raise "Not Implemented"
        end
      end
    end
  end
end
