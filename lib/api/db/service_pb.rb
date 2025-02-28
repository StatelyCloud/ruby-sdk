# frozen_string_literal: true
# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: db/service.proto

require 'google/protobuf'

require 'api/db/continue_list_pb'
require 'api/db/continue_scan_pb'
require 'api/db/delete_pb'
require 'api/db/get_pb'
require 'api/db/list_pb'
require 'api/db/put_pb'
require 'api/db/scan_pb'
require 'api/db/scan_root_paths_pb'
require 'api/db/sync_list_pb'
require 'api/db/transaction_pb'


descriptor_data = "\n\x10\x64\x62/service.proto\x12\nstately.db\x1a\x16\x64\x62/continue_list.proto\x1a\x16\x64\x62/continue_scan.proto\x1a\x0f\x64\x62/delete.proto\x1a\x0c\x64\x62/get.proto\x1a\rdb/list.proto\x1a\x0c\x64\x62/put.proto\x1a\rdb/scan.proto\x1a\x18\x64\x62/scan_root_paths.proto\x1a\x12\x64\x62/sync_list.proto\x1a\x14\x64\x62/transaction.proto2\x8c\x06\n\x0f\x44\x61tabaseService\x12;\n\x03Put\x12\x16.stately.db.PutRequest\x1a\x17.stately.db.PutResponse\"\x03\x90\x02\x02\x12;\n\x03Get\x12\x16.stately.db.GetRequest\x1a\x17.stately.db.GetResponse\"\x03\x90\x02\x01\x12\x44\n\x06\x44\x65lete\x12\x19.stately.db.DeleteRequest\x1a\x1a.stately.db.DeleteResponse\"\x03\x90\x02\x02\x12J\n\tBeginList\x12\x1c.stately.db.BeginListRequest\x1a\x18.stately.db.ListResponse\"\x03\x90\x02\x01\x30\x01\x12P\n\x0c\x43ontinueList\x12\x1f.stately.db.ContinueListRequest\x1a\x18.stately.db.ListResponse\"\x03\x90\x02\x01\x30\x01\x12J\n\tBeginScan\x12\x1c.stately.db.BeginScanRequest\x1a\x18.stately.db.ListResponse\"\x03\x90\x02\x01\x30\x01\x12P\n\x0c\x43ontinueScan\x12\x1f.stately.db.ContinueScanRequest\x1a\x18.stately.db.ListResponse\"\x03\x90\x02\x01\x30\x01\x12L\n\x08SyncList\x12\x1b.stately.db.SyncListRequest\x1a\x1c.stately.db.SyncListResponse\"\x03\x90\x02\x01\x30\x01\x12T\n\x0bTransaction\x12\x1e.stately.db.TransactionRequest\x1a\x1f.stately.db.TransactionResponse\"\x00(\x01\x30\x01\x12Y\n\rScanRootPaths\x12 .stately.db.ScanRootPathsRequest\x1a!.stately.db.ScanRootPathsResponse\"\x03\x90\x02\x01\x42g\n\x0e\x63om.stately.dbB\x0cServiceProtoP\x01\xa2\x02\x03SDX\xaa\x02\nStately.Db\xca\x02\nStately\\Db\xe2\x02\x16Stately\\Db\\GPBMetadata\xea\x02\x0bStately::Dbb\x06proto3"

pool = Google::Protobuf::DescriptorPool.generated_pool
pool.add_serialized_file(descriptor_data)

module Stately
  module Db
  end
end
