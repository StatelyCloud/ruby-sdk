# frozen_string_literal: true

require "error"
require "grpc"

module StatelyDB
  module Common
    # GRPC interceptor to convert errors to StatelyDB::Error
    class ErrorInterceptor < GRPC::ClientInterceptor
      # Client and Server stream handling logic
      %i[request_response client_streamer server_streamer bidi_streamer].each do |method_name|
        define_method(method_name) do |*args, &block|
          safe_yield(*args, &block)
        end
      end
    end
  end
end

def safe_yield(*, &block)
  block.call(*)
rescue Exception => e
  raise StatelyDB::Error.from(e)
end

def safe_yield_stream(stream, &block)
  stream.each do |msg|
    safe_yield(msg, &block)
  end
rescue Exception => e
  raise StatelyDB::Error.from(e)
end
