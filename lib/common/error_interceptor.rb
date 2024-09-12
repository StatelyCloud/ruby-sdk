# frozen_string_literal: true

require "error"
require "grpc"

module StatelyDB
  module Common
    # GRPC interceptor to convert errors to StatelyDB::Error
    class ErrorInterceptor < GRPC::ClientInterceptor
      # client unary interceptor
      def request_response(request:, call:, method:, metadata:) # rubocop:disable Lint/UnusedMethodArgument
        yield
      rescue Exception => e
        raise StatelyDB::Error.from(e)
      end

      # client streaming interceptor
      def client_streamer(requests:, call:, method:, metadata:) # rubocop:disable Lint/UnusedMethodArgument
        yield
      rescue Exception => e
        raise StatelyDB::Error.from(e)
      end

      # server streaming interceptor
      def server_streamer(request:, call:, method:, metadata:) # rubocop:disable Lint/UnusedMethodArgument
        yield
      rescue Exception => e
        raise StatelyDB::Error.from(e)
      end

      # bidirectional streaming interceptor
      def bidi_streamer(requests:, call:, method:, metadata:) # rubocop:disable Lint/UnusedMethodArgument
        yield
      rescue Exception => e
        raise StatelyDB::Error.from(e)
      end
    end
  end
end
