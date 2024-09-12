# frozen_string_literal: true

require "error"
require "grpc"
require "google/protobuf/any_pb"
require "google/rpc/status_pb"

describe StatelyDB::Error do
  it "can be constructed directly" do
    error = described_class.new("message", code: 3, stately_code: "ErrInvalidArgument")
    expect(error.message).to eq("(InvalidArgument/ErrInvalidArgument): message")
    expect(error.code).to eq(3)
    expect(error.stately_code).to eq("ErrInvalidArgument")
    expect(error.cause).to be_nil
  end

  it "can convert from a GRPC::BadStatus" do
    grpc_error = GRPC::BadStatus.new(3, "message")
    stately_details = Stately::Errors::StatelyErrorDetails.new(
      message: "message extended",
      stately_code: "ErrInvalidArgument", upstream_cause: "a problem upstream"
    )
    details = Google::Rpc::Status.new(details: [Google::Protobuf::Any.new(
      type_url: "type.googleapis.com/stately.errors.StatelyErrorDetails",
      value: Stately::Errors::StatelyErrorDetails.encode(stately_details).to_s
    )])
    grpc_error.metadata["grpc-status-details-bin"] = Google::Rpc::Status.encode(details).to_s

    error = described_class.from(grpc_error)
    expect(error.message).to eq("(InvalidArgument/ErrInvalidArgument): message extended")
    expect(error.code).to eq(3)
    expect(error.stately_code).to eq("ErrInvalidArgument")
    expect(error.cause).to be_a(StandardError)
    expect(error.cause.message).to eq("a problem upstream")
  end

  it "can convert from a normal error" do
    error = StandardError.new("message")
    converted = described_class.from(error)
    expect(converted.message).to eq("(Unknown/Unknown): message")
    expect(converted.code).to eq(2)
    expect(converted.stately_code).to eq("Unknown")
    expect(converted.cause).to eq(error)
  end
end
