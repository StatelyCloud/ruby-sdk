# frozen_string_literal: true

# Add the pb dir to the LOAD_PATH because generated proto imports are not relative and
# we don't want the protos polluting the main namespace.
# Tracking here: https://github.com/grpc/grpc/issues/6164
$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/api"

require "api/errors/error_details_pb"

module StatelyDB
  # The Error class contains common StatelyDB error types.
  class Error < StandardError
    # The gRPC/Connect Code for this error.
    # @return [Integer]
    attr_reader :code
    # The more fine-grained Stately error code, which is a human-readable string.
    # @return [String]
    attr_reader :stately_code
    # The upstream cause of the error, if available.
    # @return [Exception]
    attr_reader :cause

    # @param [String] message
    # @param [Integer] code
    # @param [String] stately_code
    # @param [Exception] cause
    def initialize(message, code: nil, stately_code: nil, cause: nil)
      code_str = self.class.grpc_code_to_string(code)

      super("(#{code_str}/#{stately_code}): #{message}")
      @code = code
      @stately_code = stately_code
      @cause = cause
    end

    # Convert any exception into a StatelyDB::Error.
    # @param [Exception] error
    # @return [StatelyDB::Error]
    def self.from(error)
      return error if error.is_a?(StatelyDB::Error)

      if error.is_a?(GRPC::BadStatus)
        status = error.to_rpc_status

        unless status.nil? || status.details.empty?
          raw_detail = status.details[0]
          if raw_detail.type_url == "type.googleapis.com/stately.errors.StatelyErrorDetails"
            error_details = Stately::Errors::StatelyErrorDetails.decode(raw_detail.value)
            upstream_cause = error_details.upstream_cause.empty? ? nil : StandardError.new(error_details.upstream_cause) # rubocop:disable Metrics/BlockNesting
            return new(error_details.message, code: error.code, stately_code: error_details.stately_code,
                                              cause: upstream_cause)
          end
        end
      end

      new(error.message, code: GRPC::Core::StatusCodes::UNKNOWN, stately_code: "Unknown", cause: error)
    end

    # Turn this error's gRPC status code into a human-readable string. e.g. 3 -> "InvalidArgument"
    # @return [String]
    def code_string
      self.class.grpc_code_to_string(@code)
    end

    # Turn a gRPC status code into a human-readable string. e.g. 3 -> "InvalidArgument"
    # @param [Integer] code
    # @return [String]
    def self.grpc_code_to_string(code)
      if code > 0
        GRPC::Core::StatusCodes.constants.find do |c|
          GRPC::Core::StatusCodes.const_get(c) === code
        end.to_s.split("_").collect(&:capitalize).join
      else
        "Unknown"
      end
    end
  end
end
