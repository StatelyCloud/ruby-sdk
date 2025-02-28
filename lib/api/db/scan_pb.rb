# frozen_string_literal: true
# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: db/scan.proto

require 'google/protobuf'


descriptor_data = "\n\rdb/scan.proto\x12\nstately.db\"9\n\x0f\x46ilterCondition\x12\x1d\n\titem_type\x18\x01 \x01(\tH\x00R\x08itemTypeB\x07\n\x05value\"\x88\x02\n\x10\x42\x65ginScanRequest\x12\x19\n\x08store_id\x18\x01 \x01(\x04R\x07storeId\x12\x46\n\x10\x66ilter_condition\x18\x02 \x03(\x0b\x32\x1b.stately.db.FilterConditionR\x0f\x66ilterCondition\x12\x14\n\x05limit\x18\x03 \x01(\rR\x05limit\x12O\n\x13segmentation_params\x18\x04 \x01(\x0b\x32\x1e.stately.db.SegmentationParamsR\x12segmentationParams\x12*\n\x11schema_version_id\x18\x05 \x01(\rR\x0fschemaVersionId\"`\n\x12SegmentationParams\x12%\n\x0etotal_segments\x18\x05 \x01(\rR\rtotalSegments\x12#\n\rsegment_index\x18\x06 \x01(\rR\x0csegmentIndexBd\n\x0e\x63om.stately.dbB\tScanProtoP\x01\xa2\x02\x03SDX\xaa\x02\nStately.Db\xca\x02\nStately\\Db\xe2\x02\x16Stately\\Db\\GPBMetadata\xea\x02\x0bStately::Dbb\x06proto3"

pool = Google::Protobuf::DescriptorPool.generated_pool
pool.add_serialized_file(descriptor_data)

module Stately
  module Db
    FilterCondition = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.FilterCondition").msgclass
    BeginScanRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.BeginScanRequest").msgclass
    SegmentationParams = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.SegmentationParams").msgclass
  end
end
