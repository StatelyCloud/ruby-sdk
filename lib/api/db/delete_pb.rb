# frozen_string_literal: true
# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: db/delete.proto

require 'google/protobuf'


descriptor_data = "\n\x0f\x64\x62/delete.proto\x12\nstately.db\"b\n\rDeleteRequest\x12\x19\n\x08store_id\x18\x01 \x01(\x04R\x07storeId\x12\x30\n\x07\x64\x65letes\x18\x03 \x03(\x0b\x32\x16.stately.db.DeleteItemR\x07\x64\x65letesJ\x04\x08\x04\x10\x05\"\'\n\nDeleteItem\x12\x19\n\x08key_path\x18\x01 \x01(\tR\x07keyPath\"/\n\x0c\x44\x65leteResult\x12\x19\n\x08key_path\x18\x01 \x01(\tR\x07keyPathJ\x04\x08\x02\x10\x03\"D\n\x0e\x44\x65leteResponse\x12\x32\n\x07results\x18\x01 \x03(\x0b\x32\x18.stately.db.DeleteResultR\x07resultsBf\n\x0e\x63om.stately.dbB\x0b\x44\x65leteProtoP\x01\xa2\x02\x03SDX\xaa\x02\nStately.Db\xca\x02\nStately\\Db\xe2\x02\x16Stately\\Db\\GPBMetadata\xea\x02\x0bStately::Dbb\x06proto3"

pool = Google::Protobuf::DescriptorPool.generated_pool
pool.add_serialized_file(descriptor_data)

module Stately
  module Db
    DeleteRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.DeleteRequest").msgclass
    DeleteItem = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.DeleteItem").msgclass
    DeleteResult = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.DeleteResult").msgclass
    DeleteResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.DeleteResponse").msgclass
  end
end
