# frozen_string_literal: true
# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: db/continue_scan.proto

require 'google/protobuf'


descriptor_data = "\n\x16\x64\x62/continue_scan.proto\x12\nstately.db\"}\n\x13\x43ontinueScanRequest\x12\x1d\n\ntoken_data\x18\x01 \x01(\x0cR\ttokenData\x12*\n\x11schema_version_id\x18\x02 \x01(\rR\x0fschemaVersionId\x12\x1b\n\tschema_id\x18\x03 \x01(\x04R\x08schemaIdBl\n\x0e\x63om.stately.dbB\x11\x43ontinueScanProtoP\x01\xa2\x02\x03SDX\xaa\x02\nStately.Db\xca\x02\nStately\\Db\xe2\x02\x16Stately\\Db\\GPBMetadata\xea\x02\x0bStately::Dbb\x06proto3"

pool = Google::Protobuf::DescriptorPool.generated_pool
pool.add_serialized_file(descriptor_data)

module Stately
  module Db
    ContinueScanRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.ContinueScanRequest").msgclass
  end
end
