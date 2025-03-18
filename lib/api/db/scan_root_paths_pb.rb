# frozen_string_literal: true
# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: db/scan_root_paths.proto

require 'google/protobuf'


descriptor_data = "\n\x18\x64\x62/scan_root_paths.proto\x12\nstately.db\"\xbb\x01\n\x14ScanRootPathsRequest\x12\x19\n\x08store_id\x18\x01 \x01(\x04R\x07storeId\x12\x14\n\x05limit\x18\x02 \x01(\rR\x05limit\x12)\n\x10pagination_token\x18\x03 \x01(\x0cR\x0fpaginationToken\x12*\n\x11schema_version_id\x18\x04 \x01(\rR\x0fschemaVersionId\x12\x1b\n\tschema_id\x18\x05 \x01(\x04R\x08schemaId\"|\n\x15ScanRootPathsResponse\x12\x38\n\x07results\x18\x01 \x03(\x0b\x32\x1e.stately.db.ScanRootPathResultR\x07results\x12)\n\x10pagination_token\x18\x02 \x01(\x0cR\x0fpaginationToken\"/\n\x12ScanRootPathResult\x12\x19\n\x08key_path\x18\x01 \x01(\tR\x07keyPathBm\n\x0e\x63om.stately.dbB\x12ScanRootPathsProtoP\x01\xa2\x02\x03SDX\xaa\x02\nStately.Db\xca\x02\nStately\\Db\xe2\x02\x16Stately\\Db\\GPBMetadata\xea\x02\x0bStately::Dbb\x06proto3"

pool = Google::Protobuf::DescriptorPool.generated_pool
pool.add_serialized_file(descriptor_data)

module Stately
  module Db
    ScanRootPathsRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.ScanRootPathsRequest").msgclass
    ScanRootPathsResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.ScanRootPathsResponse").msgclass
    ScanRootPathResult = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.ScanRootPathResult").msgclass
  end
end
