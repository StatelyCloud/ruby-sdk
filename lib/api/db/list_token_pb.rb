# frozen_string_literal: true
# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: db/list_token.proto

require 'google/protobuf'


descriptor_data = "\n\x13\x64\x62/list_token.proto\x12\nstately.db\"\x94\x01\n\tListToken\x12\x1d\n\ntoken_data\x18\x01 \x01(\x0cR\ttokenData\x12!\n\x0c\x63\x61n_continue\x18\x02 \x01(\x08R\x0b\x63\x61nContinue\x12\x19\n\x08\x63\x61n_sync\x18\x03 \x01(\x08R\x07\x63\x61nSync\x12*\n\x11schema_version_id\x18\x04 \x01(\rR\x0fschemaVersionIdBi\n\x0e\x63om.stately.dbB\x0eListTokenProtoP\x01\xa2\x02\x03SDX\xaa\x02\nStately.Db\xca\x02\nStately\\Db\xe2\x02\x16Stately\\Db\\GPBMetadata\xea\x02\x0bStately::Dbb\x06proto3"

pool = Google::Protobuf::DescriptorPool.generated_pool
pool.add_serialized_file(descriptor_data)

module Stately
  module Db
    ListToken = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.ListToken").msgclass
  end
end
