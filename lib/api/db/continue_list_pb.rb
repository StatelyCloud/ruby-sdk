# frozen_string_literal: true
# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: db/continue_list.proto

require 'google/protobuf'


descriptor_data = "\n\x16\x64\x62/continue_list.proto\x12\nstately.db\"\xbe\x01\n\x13\x43ontinueListRequest\x12\x1d\n\ntoken_data\x18\x01 \x01(\x0cR\ttokenData\x12?\n\tdirection\x18\x02 \x01(\x0e\x32!.stately.db.ContinueListDirectionR\tdirection\x12*\n\x11schema_version_id\x18\x05 \x01(\rR\x0fschemaVersionId\x12\x1b\n\tschema_id\x18\x06 \x01(\x04R\x08schemaId*N\n\x15\x43ontinueListDirection\x12\x19\n\x15\x43ONTINUE_LIST_FORWARD\x10\x00\x12\x1a\n\x16\x43ONTINUE_LIST_BACKWARD\x10\x01\x42l\n\x0e\x63om.stately.dbB\x11\x43ontinueListProtoP\x01\xa2\x02\x03SDX\xaa\x02\nStately.Db\xca\x02\nStately\\Db\xe2\x02\x16Stately\\Db\\GPBMetadata\xea\x02\x0bStately::Dbb\x06proto3"

pool = Google::Protobuf::DescriptorPool.generated_pool
pool.add_serialized_file(descriptor_data)

module Stately
  module Db
    ContinueListRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.ContinueListRequest").msgclass
    ContinueListDirection = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.ContinueListDirection").enummodule
  end
end
