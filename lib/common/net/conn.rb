# frozen_string_literal: true

require "grpc"
require "uri"

module StatelyDB
  module Common
    # A module for Stately Cloud networking code
    module Net
      # Create a new gRPC channel
      # @param [String] endpoint The endpoint to connect to
      # @return [::GRPC::Core::Channel] The new channel
      def self.new_channel(endpoint:)
        endpoint_uri = URI(endpoint)
        creds = GRPC::Core::ChannelCredentials.new
        call_creds = GRPC::Core::CallCredentials.new(proc {})
        creds = if endpoint_uri.scheme == "http"
                  :this_channel_is_insecure
                else
                  creds.compose(call_creds)
                end
        GRPC::Core::Channel.new(endpoint_uri.authority, {
                                  # This map contains grpc channel settings.
                                  # Find the full list of supported keys
                                  # here: https://grpc.github.io/grpc/core/group__grpc__arg__keys.html

                                  # Can't make it unlimited so set INT32_MAX: ~2GB
                                  # https://groups.google.com/g/grpc-io/c/FoLNUJVN4o4
                                  # We set max_ and absolute_max_ to the same value
                                  # to stop the grpc lib changing the error code to ResourceExhausted
                                  # while still successfully reading the metadata because only the soft
                                  # limit was exceeded.
                                  "grpc.max_metadata_size" => (2**31) - 1,
                                  "grpc.absolute_max_metadata_size" => (2**31) - 1
                                }, creds)
      end
    end
  end
end
