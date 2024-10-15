# frozen_string_literal: true
# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: db/transaction.proto

require 'google/protobuf'

require 'db/continue_list_pb'
require 'db/delete_pb'
require 'db/get_pb'
require 'db/item_pb'
require 'db/item_property_pb'
require 'db/list_pb'
require 'db/put_pb'
require 'google/protobuf/empty_pb'


descriptor_data = "\n\x14\x64\x62/transaction.proto\x12\nstately.db\x1a\x16\x64\x62/continue_list.proto\x1a\x0f\x64\x62/delete.proto\x1a\x0c\x64\x62/get.proto\x1a\rdb/item.proto\x1a\x16\x64\x62/item_property.proto\x1a\rdb/list.proto\x1a\x0c\x64\x62/put.proto\x1a\x1bgoogle/protobuf/empty.proto\"\x9f\x04\n\x12TransactionRequest\x12\x1d\n\nmessage_id\x18\x01 \x01(\rR\tmessageId\x12\x34\n\x05\x62\x65gin\x18\x02 \x01(\x0b\x32\x1c.stately.db.TransactionBeginH\x00R\x05\x62\x65gin\x12\x39\n\tget_items\x18\x03 \x01(\x0b\x32\x1a.stately.db.TransactionGetH\x00R\x08getItems\x12\x41\n\nbegin_list\x18\x04 \x01(\x0b\x32 .stately.db.TransactionBeginListH\x00R\tbeginList\x12J\n\rcontinue_list\x18\x05 \x01(\x0b\x32#.stately.db.TransactionContinueListH\x00R\x0c\x63ontinueList\x12\x39\n\tput_items\x18\x06 \x01(\x0b\x32\x1a.stately.db.TransactionPutH\x00R\x08putItems\x12\x42\n\x0c\x64\x65lete_items\x18\x07 \x01(\x0b\x32\x1d.stately.db.TransactionDeleteH\x00R\x0b\x64\x65leteItems\x12\x30\n\x06\x63ommit\x18\x08 \x01(\x0b\x32\x16.google.protobuf.EmptyH\x00R\x06\x63ommit\x12.\n\x05\x61\x62ort\x18\t \x01(\x0b\x32\x16.google.protobuf.EmptyH\x00R\x05\x61\x62ortB\t\n\x07\x63ommand\"\xc8\x02\n\x13TransactionResponse\x12\x1d\n\nmessage_id\x18\x01 \x01(\rR\tmessageId\x12\x45\n\x0bget_results\x18\x02 \x01(\x0b\x32\".stately.db.TransactionGetResponseH\x00R\ngetResults\x12\x38\n\x07put_ack\x18\x03 \x01(\x0b\x32\x1d.stately.db.TransactionPutAckH\x00R\x06putAck\x12H\n\x0clist_results\x18\x04 \x01(\x0b\x32#.stately.db.TransactionListResponseH\x00R\x0blistResults\x12=\n\x08\x66inished\x18\x05 \x01(\x0b\x32\x1f.stately.db.TransactionFinishedH\x00R\x08\x66inishedB\x08\n\x06result\"Y\n\x10TransactionBegin\x12\x19\n\x08store_id\x18\x01 \x01(\x04R\x07storeId\x12*\n\x11schema_version_id\x18\x02 \x01(\rR\x0fschemaVersionId\"9\n\x0eTransactionGet\x12\'\n\x04gets\x18\x01 \x03(\x0b\x32\x13.stately.db.GetItemR\x04gets\"\xd9\x01\n\x14TransactionBeginList\x12&\n\x0fkey_path_prefix\x18\x01 \x01(\tR\rkeyPathPrefix\x12\x14\n\x05limit\x18\x02 \x01(\rR\x05limit\x12\x41\n\rsort_property\x18\x03 \x01(\x0e\x32\x1c.stately.db.SortablePropertyR\x0csortProperty\x12@\n\x0esort_direction\x18\x04 \x01(\x0e\x32\x19.stately.db.SortDirectionR\rsortDirection\"y\n\x17TransactionContinueList\x12\x1d\n\ntoken_data\x18\x01 \x01(\x0cR\ttokenData\x12?\n\tdirection\x18\x04 \x01(\x0e\x32!.stately.db.ContinueListDirectionR\tdirection\"9\n\x0eTransactionPut\x12\'\n\x04puts\x18\x01 \x03(\x0b\x32\x13.stately.db.PutItemR\x04puts\"E\n\x11TransactionDelete\x12\x30\n\x07\x64\x65letes\x18\x01 \x03(\x0b\x32\x16.stately.db.DeleteItemR\x07\x64\x65letes\"@\n\x16TransactionGetResponse\x12&\n\x05items\x18\x01 \x03(\x0b\x32\x10.stately.db.ItemR\x05items\"D\n\x0bGeneratedID\x12\x14\n\x04uint\x18\x01 \x01(\x04H\x00R\x04uint\x12\x16\n\x05\x62ytes\x18\x02 \x01(\x0cH\x00R\x05\x62ytesB\x07\n\x05value\"Q\n\x11TransactionPutAck\x12<\n\rgenerated_ids\x18\x01 \x03(\x0b\x32\x17.stately.db.GeneratedIDR\x0cgeneratedIds\"\x96\x01\n\x17TransactionListResponse\x12\x37\n\x06result\x18\x01 \x01(\x0b\x32\x1d.stately.db.ListPartialResultH\x00R\x06result\x12\x36\n\x08\x66inished\x18\x02 \x01(\x0b\x32\x18.stately.db.ListFinishedH\x00R\x08\x66inishedB\n\n\x08response\"\xa7\x01\n\x13TransactionFinished\x12\x1c\n\tcommitted\x18\x01 \x01(\x08R\tcommitted\x12\x31\n\x0bput_results\x18\x02 \x03(\x0b\x32\x10.stately.db.ItemR\nputResults\x12?\n\x0e\x64\x65lete_results\x18\x03 \x03(\x0b\x32\x18.stately.db.DeleteResultR\rdeleteResultsBk\n\x0e\x63om.stately.dbB\x10TransactionProtoP\x01\xa2\x02\x03SDX\xaa\x02\nStately.Db\xca\x02\nStately\\Db\xe2\x02\x16Stately\\Db\\GPBMetadata\xea\x02\x0bStately::Dbb\x06proto3"

pool = Google::Protobuf::DescriptorPool.generated_pool
pool.add_serialized_file(descriptor_data)

module Stately
  module Db
    TransactionRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.TransactionRequest").msgclass
    TransactionResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.TransactionResponse").msgclass
    TransactionBegin = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.TransactionBegin").msgclass
    TransactionGet = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.TransactionGet").msgclass
    TransactionBeginList = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.TransactionBeginList").msgclass
    TransactionContinueList = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.TransactionContinueList").msgclass
    TransactionPut = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.TransactionPut").msgclass
    TransactionDelete = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.TransactionDelete").msgclass
    TransactionGetResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.TransactionGetResponse").msgclass
    GeneratedID = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.GeneratedID").msgclass
    TransactionPutAck = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.TransactionPutAck").msgclass
    TransactionListResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.TransactionListResponse").msgclass
    TransactionFinished = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.TransactionFinished").msgclass
  end
end
