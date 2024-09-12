# frozen_string_literal: true

require "grpc"
require "uri"

module StatelyDB
  module Common
    # A module for Stately Cloud networking code
    module Net
      # Create a new gRPC channel
      # @param [String] endpoint The endpoint to connect to
      # @return [GRPC::Core::Channel] The new channel
      def self.new_channel(endpoint: "https://api.stately.cloud")
        endpoint_uri = URI(endpoint)
        creds = GRPC::Core::ChannelCredentials.new
        call_creds = GRPC::Core::CallCredentials.new(proc {})
        creds = if endpoint_uri.scheme == "http"
                  :this_channel_is_insecure
                else
                  creds.compose(call_creds)
                end
        GRPC::Core::Channel.new(endpoint_uri.authority, {
                                  # 2x the default of 8kb = 16kb
                                  # Set max and absolute max to the same value
                                  # to stop the grpc lib changing the error code to ResourceExhausted
                                  # while still successfully reading the metadata because only the soft
                                  # limit was exceeded.
                                  "grpc.max_metadata_size" => 8192 * 2,
                                  "grpc.absolute_max_metadata_size" => 8192 * 2
                                }, creds)
      end
    end
  end
end
