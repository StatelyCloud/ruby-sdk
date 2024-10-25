# Generated by the protocol buffer compiler.  DO NOT EDIT!
# Source: db/service.proto for package 'Stately.Db'

require 'grpc'
require 'db/service_pb'

module Stately
  module Db
    module DatabaseService
      # DatabaseService is the service for creating, reading, updating and deleting data
      # in a StatelyDB Store. Creating and modifying Stores is done by
      # stately.dbmanagement.ManagementService.
      class Service

        include ::GRPC::GenericService

        self.marshal_class_method = :encode
        self.unmarshal_class_method = :decode
        self.service_name = 'stately.db.DatabaseService'

        # Put adds one or more Items to the Store, or replaces the Items if they
        # already exist. This will fail if the caller does not have permission to
        # create or update Items, if there is no schema registered for the provided
        # item type, or if an item is invalid. All puts are applied atomically;
        # either all will fail or all will succeed. If an item's schema specifies an
        # `initialValue` for one or more properties used in its key paths, and the
        # item is new, you should not provide those values - the database will choose
        # them for you, and Data must be provided as either serialized binary
        # protobuf or JSON.
        rpc :Put, ::Stately::Db::PutRequest, ::Stately::Db::PutResponse
        # Get retrieves one or more Items by their key paths. This will return any of
        # the Items that exist. It will fail if the caller does not have permission
        # to read Items. Use the List APIs if you want to retrieve multiple items but
        # don't already know the full key paths of the items you want to get.
        rpc :Get, ::Stately::Db::GetRequest, ::Stately::Db::GetResponse
        # Delete removes one or more Items from the Store by their key paths. This
        # will fail if the caller does not have permission to delete Items.
        # Tombstones will be saved for deleted items for  time, so
        # that SyncList can return information about deleted items. Deletes are
        # always applied atomically; all will fail or all will succeed.
        rpc :Delete, ::Stately::Db::DeleteRequest, ::Stately::Db::DeleteResponse
        # BeginList retrieves Items that start with a specified key path prefix. The
        # key path prefix must minimally contain a Group Key (a single key segment
        # with a namespace and an ID). BeginList will return an empty result set if
        # there are no items matching that key prefix. This API returns a token that
        # you can pass to ContinueList to expand the result set, or to SyncList to
        # get updates within the result set. This can fail if the caller does not
        # have permission to read Items.
        # buf:lint:ignore RPC_RESPONSE_STANDARD_NAME
        rpc :BeginList, ::Stately::Db::BeginListRequest, stream(::Stately::Db::ListResponse)
        # ContinueList takes the token from a BeginList call and returns more results
        # based on the original query parameters and pagination options. It has very
        # few options of its own because it is a continuation of a previous list
        # operation. It will return a new token which can be used for another
        # ContinueList call, and so on. The token is the same one used by SyncList -
        # each time you call either ContinueList or SyncList, you should pass the
        # latest version of the token, and then use the new token from the result in
        # subsequent calls. You may interleave ContinueList and SyncList calls
        # however you like, but it does not make sense to make both calls in
        # parallel. Calls to ContinueList are tied to the authorization of the
        # original BeginList call, so if the original BeginList call was allowed,
        # ContinueList with its token should also be allowed.
        # buf:lint:ignore RPC_RESPONSE_STANDARD_NAME
        rpc :ContinueList, ::Stately::Db::ContinueListRequest, stream(::Stately::Db::ListResponse)
        # SyncList returns all changes to Items within the result set of a previous
        # List operation. For all Items within the result set that were modified, it
        # returns the full Item at in its current state. It also returns a list of
        # Item key paths that were deleted since the last SyncList, which you should
        # reconcile with your view of items returned from previous
        # BeginList/ContinueList calls. Using this API, you can start with an initial
        # set of items from BeginList, and then stay up to date on any changes via
        # repeated SyncList requests over time. The token is the same one used by
        # ContinueList - each time you call either ContinueList or SyncList, you
        # should pass the latest version of the token, and then use the new token
        # from the result in subsequent calls. Note that if the result set has
        # already been expanded to the end (in the direction of the original
        # BeginList request), SyncList will return newly created Items. You may
        # interleave ContinueList and SyncList calls however you like, but it does
        # not make sense to make both calls in parallel. Calls to SyncList are tied
        # to the authorization of the original BeginList call, so if the original
        # BeginList call was allowed, SyncList with its token should also be allowed.
        rpc :SyncList, ::Stately::Db::SyncListRequest, stream(::Stately::Db::SyncListResponse)
        # Transaction performs a transaction, within which you can issue writes
        # (Put/Delete) and reads (Get/List) in any order, followed by a commit
        # message. Reads are guaranteed to reflect the state as of when the
        # transaction started, and writes are committed atomically. This method may
        # fail if another transaction commits before this one finishes - in that
        # case, you should retry your transaction.
        rpc :Transaction, stream(::Stately::Db::TransactionRequest), stream(::Stately::Db::TransactionResponse)
        # ScanRootPaths lists root paths (Groups) in the Store. This is a very
        # expensive operation, as it must consult multiple partitions and it reads
        # and ignores a lot of data. It is provided for use in the web console's data
        # browser and is not exposed to customers. This operation will fail if the
        # caller does not have permission to read Items.
        rpc :ScanRootPaths, ::Stately::Db::ScanRootPathsRequest, ::Stately::Db::ScanRootPathsResponse
      end

      Stub = Service.rpc_stub_class
    end
  end
end
