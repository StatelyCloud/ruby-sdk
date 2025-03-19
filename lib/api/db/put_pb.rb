# frozen_string_literal: true
# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: db/put.proto

require 'google/protobuf'

require 'api/db/item_pb'


descriptor_data = "\n\x0c\x64\x62/put.proto\x12\nstately.db\x1a\rdb/item.proto\"\x99\x01\n\nPutRequest\x12\x19\n\x08store_id\x18\x01 \x01(\x04R\x07storeId\x12\'\n\x04puts\x18\x02 \x03(\x0b\x32\x13.stately.db.PutItemR\x04puts\x12*\n\x11schema_version_id\x18\x03 \x01(\rR\x0fschemaVersionId\x12\x1b\n\tschema_id\x18\x04 \x01(\x04R\x08schemaId\"\x99\x01\n\x07PutItem\x12$\n\x04item\x18\x01 \x01(\x0b\x32\x10.stately.db.ItemR\x04item\x12\x42\n\x1doverwrite_metadata_timestamps\x18\x02 \x01(\x08R\x1boverwriteMetadataTimestamps\x12$\n\x0emust_not_exist\x18\x03 \x01(\x08R\x0cmustNotExist\"5\n\x0bPutResponse\x12&\n\x05items\x18\x01 \x03(\x0b\x32\x10.stately.db.ItemR\x05itemsBc\n\x0e\x63om.stately.dbB\x08PutProtoP\x01\xa2\x02\x03SDX\xaa\x02\nStately.Db\xca\x02\nStately\\Db\xe2\x02\x16Stately\\Db\\GPBMetadata\xea\x02\x0bStately::Dbb\x06proto3"

pool = Google::Protobuf::DescriptorPool.generated_pool
pool.add_serialized_file(descriptor_data)

module Stately
  module Db
    PutRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.PutRequest").msgclass
    PutItem = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.PutItem").msgclass
    PutResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.PutResponse").msgclass
  end
end
