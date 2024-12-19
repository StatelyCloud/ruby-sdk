# frozen_string_literal: true

require "api/db/service_services_pb"
require "common/auth/auth_token_provider"
require "common/auth/interceptor"
require "common/net/conn"
require "common/error_interceptor"
require "grpc"
require "json"
require "net/http"

require "transaction/transaction"
require "transaction/queue"
require "error"
require "key_path"
require "token"
require "uuid"

module StatelyDB
  # CoreClient is a low level client for interacting with the Stately Cloud API.
  # This client shouldn't be used directly in most cases. Instead, use the generated
  # client for your schema.
  class CoreClient
    # Initialize a new StatelyDB CoreClient
    #
    # @param store_id [Integer] the StatelyDB to use for all operations with this client.
    # @param schema [Module] the generated Schema module to use for mapping StatelyDB Items.
    # @param token_provider [Common::Auth::TokenProvider] the token provider to use for authentication.
    # @param endpoint [String] the endpoint to connect to.
    # @param region [String] the region to connect to.
    def initialize(store_id:,
                   schema:,
                   token_provider: Common::Auth::AuthTokenProvider.new,
                   endpoint: nil,
                   region: nil)
      if store_id.nil?
        raise StatelyDB::Error.new("store_id is required",
                                   code: GRPC::Core::StatusCodes::INVALID_ARGUMENT,
                                   stately_code: "InvalidArgument")
      end
      if schema.nil?
        raise StatelyDB::Error.new("schema is required",
                                   code: GRPC::Core::StatusCodes::INVALID_ARGUMENT,
                                   stately_code: "InvalidArgument")
      end

      endpoint = self.class.make_endpoint(endpoint:, region:)
      @channel = Common::Net.new_channel(endpoint:)
      @token_provider = token_provider

      auth_interceptor = Common::Auth::Interceptor.new(token_provider:)
      error_interceptor = Common::ErrorInterceptor.new

      @stub = Stately::Db::DatabaseService::Stub.new(nil, nil, channel_override: @channel,
                                                               interceptors: [error_interceptor, auth_interceptor])
      @store_id = store_id.to_i
      @schema = schema
      @allow_stale = false
    end

    # @return [void] nil
    def close
      @channel&.close
      @token_provider&.close
    end

    # Set whether to allow stale results for all operations with this client. This produces a new client
    # with the allow_stale flag set.
    # @param allow_stale [Boolean] whether to allow stale results
    # @return [self] a new client with the allow_stale flag set
    # @example
    #  client.with_allow_stale(true).get("/ItemType-identifier")
    def with_allow_stale(allow_stale)
      new_client = clone
      new_client.instance_variable_set(:@allow_stale, allow_stale)
      new_client
    end

    # Fetch a single Item from a StatelyDB Store at the given key_path.
    #
    # @param key_path [String] the path to the item
    # @return [StatelyDB::Item, NilClass] the Item or nil if not found
    # @raise [StatelyDB::Error] if the parameters are invalid or if the item is not found
    #
    # @example
    #   client.get("/ItemType-identifier")
    def get(key_path)
      resp = get_batch(key_path)

      # Always return a single Item.
      resp.first
    end

    # Fetch a batch of up to 100 Items from a StatelyDB Store at the given key_paths.
    #
    # @param key_paths [String, Array<String>] the paths to the items. Max 100 key paths.
    # @return [Array<StatelyDB::Item>, NilClass] the items or nil if not found
    # @raise [StatelyDB::Error] if the parameters are invalid or if the item is not found
    #
    # @example
    #   client.data.get_batch("/ItemType-identifier", "/ItemType-identifier2")
    def get_batch(*key_paths)
      key_paths = Array(key_paths).flatten
      req = Stately::Db::GetRequest.new(
        store_id: @store_id,
        schema_version_id: @schema::SCHEMA_VERSION_ID,
        gets:
          key_paths.map { |key_path| Stately::Db::GetItem.new(key_path: String(key_path)) },
        allow_stale: @allow_stale
      )

      resp = @stub.get(req)
      resp.items.map do |result|
        @schema.unmarshal_item(stately_item: result)
      end
    end

    # Begin listing Items from a StatelyDB Store at the given prefix.
    #
    # @param prefix [String] the prefix to list
    # @param limit [Integer] the maximum number of items to return
    # @param sort_property [String] the property to sort by
    # @param sort_direction [Symbol] the direction to sort by (:ascending or :descending)
    # @return [Array<StatelyDB::Item>, StatelyDB::Token] the list of Items and the token
    #
    # @example
    #   client.data.begin_list("/ItemType-identifier", limit: 10, sort_direction: :ascending)
    def begin_list(prefix,
                   limit: 100,
                   sort_property: nil,
                   sort_direction: :ascending)
      sort_direction = sort_direction == :ascending ? 0 : 1

      req = Stately::Db::BeginListRequest.new(
        store_id: @store_id,
        key_path_prefix: String(prefix),
        limit:,
        sort_property:,
        sort_direction:,
        allow_stale: @allow_stale,
        schema_version_id: @schema::SCHEMA_VERSION_ID
      )
      resp = @stub.begin_list(req)
      process_list_response(resp)
    end

    # Continue listing Items from a StatelyDB Store using a token.
    #
    # @param token [StatelyDB::Token] the token to continue from
    # @return [Array<StatelyDB::Item>, StatelyDB::Token] the list of Items and the token
    #
    # @example
    #   (items, token) = client.data.begin_list("/ItemType-identifier")
    #   client.data.continue_list(token)
    def continue_list(token)
      req = Stately::Db::ContinueListRequest.new(
        token_data: token.token_data,
        schema_version_id: @schema::SCHEMA_VERSION_ID
      )
      resp = @stub.continue_list(req)
      process_list_response(resp)
    end

    # Sync a list of Items from a StatelyDB Store.
    #
    # @param token [StatelyDB::Token] the token to sync from
    # @return [StatelyDB::SyncResult] the result of the sync operation
    #
    # @example
    #   (items, token) = client.data.begin_list("/ItemType-identifier")
    #   client.data.sync_list(token)
    def sync_list(token)
      req = Stately::Db::SyncListRequest.new(
        token_data: token.token_data,
        schema_version_id: @schema::SCHEMA_VERSION_ID
      )
      resp = @stub.sync_list(req)
      process_sync_response(resp)
    end

    # Put an Item into a StatelyDB Store at the given key_path.
    #
    # @param item [StatelyDB::Item] a StatelyDB Item
    # @param must_not_exist [Boolean] A condition that indicates this item must
    #   not already exist at any of its key paths. If there is already an item
    #   at one of those paths, the Put operation will fail with a
    #   "ConditionalCheckFailed" error. Note that if the item has an
    #   `initialValue` field in its key, that initial value will automatically
    #   be chosen not to conflict with existing items, so this condition only
    #   applies to key paths that do not contain the `initialValue` field.
    # @param overwrite_metadata_timestamps [Boolean] If set to true, the server will
    #   set the `createdAtTime` and/or `lastModifiedAtTime` fields based on the
    #   current values in this item (assuming you've mapped them to a field using
    #   `fromMetadata`). Without this, those fields are always ignored and the
    #   server sets them to the appropriate times. This option can be useful when
    #   migrating data from another system.
    # @return [StatelyDB::Item] the item that was stored
    #
    # @example client.data.put(my_item)
    # @example client.data.put(my_item, must_not_exist: true)
    def put(item,
            must_not_exist: false,
            overwrite_metadata_timestamps: false)
      resp = put_batch({ item:, must_not_exist:, overwrite_metadata_timestamps: })

      # Always return a single Item.
      resp.first
    end

    # Put a batch of up to 50 Items into a StatelyDB Store.
    #
    # @param items [StatelyDB::Item, Array<StatelyDB::Item>] the items to store.
    # Max 50 items.
    # @return [Array<StatelyDB::Item>] the items that were stored
    #
    # @example
    #   client.data.put_batch(item1, item2)
    # @example
    #  client.data.put_batch({ item: item1, must_not_exist: true }, item2)
    def put_batch(*items)
      puts = Array(items).flatten.map do |input|
        if input.is_a?(Hash)
          item = input[:item]
          Stately::Db::PutItem.new(
            item: item.send("marshal_stately"),
            overwrite_metadata_timestamps: input[:overwrite_metadata_timestamps],
            must_not_exist: input[:must_not_exist]
          )
        else
          Stately::Db::PutItem.new(
            item: input.send("marshal_stately")
          )
        end
      end
      req = Stately::Db::PutRequest.new(
        store_id: @store_id,
        schema_version_id: @schema::SCHEMA_VERSION_ID,
        puts:
      )
      resp = @stub.put(req)

      resp.items.map do |result|
        @schema.unmarshal_item(stately_item: result)
      end
    end

    # Delete up to 50 Items from a StatelyDB Store at the given key_paths.
    #
    # @param key_paths [String, Array<String>] the paths to the items. Max 50 key paths.
    # @raise [StatelyDB::Error] if the parameters are invalid
    # @raise [StatelyDB::Error] if the item is not found
    # @return [void] nil
    #
    # @example
    #   client.data.delete("/ItemType-identifier", "/ItemType-identifier2")
    def delete(*key_paths)
      key_paths = Array(key_paths).flatten
      req = Stately::Db::DeleteRequest.new(
        store_id: @store_id,
        schema_version_id: @schema::SCHEMA_VERSION_ID,
        deletes: key_paths.map { |key_path| Stately::Db::DeleteItem.new(key_path: String(key_path)) }
      )
      @stub.delete(req)
      nil
    end

    # Transaction takes a block and executes the block within a transaction.
    # If the block raises an exception, the transaction is rolled back.
    # If the block completes successfully, the transaction is committed.
    #
    # @return [StatelyDB::Transaction::Transaction::Result] the result of the transaction
    # @raise [StatelyDB::Error] if the parameters are invalid
    # @raise [StatelyDB::Error] if the item is not found
    # @raise [Exception] if any other exception is raised
    #
    # @example
    #   client.data.transaction do |txn|
    #     txn.put(item: my_item)
    #     txn.put(item: another_item)
    #   end
    def transaction
      txn = StatelyDB::Transaction::Transaction.new(stub: @stub, store_id: @store_id, schema: @schema)
      txn.begin
      yield txn
      txn.commit
    rescue StatelyDB::Error
      raise
    # Handle any other exceptions and abort the transaction. We're rescuing Exception here
    # because we want to catch all exceptions, including those that don't inherit from StandardError.
    rescue Exception => e
      txn.abort

      # All gRPC errors inherit from GRPC::BadStatus. We wrap these in a StatelyDB::Error.
      raise StatelyDB::Error.from(e) if e.is_a? GRPC::BadStatus

      # Calling raise with no parameters re-raises the original exception
      raise
    end

    # Construct the API endpoint from the region and endpoint.
    # If the endpoint is provided, it will be returned as-is.
    # If the region is provided and the endpoint is not,
    # then the region-specific endpoint will be returned.
    # If neither the region nor the endpoint is provided,
    # then the default endpoint will be returned.
    #
    # @param endpoint [String] the endpoint to connect to
    # @param region [Region] the region to connect to
    # @return [String] the constructed endpoint
    def self.make_endpoint(endpoint: nil, region: nil)
      return endpoint unless endpoint.nil?
      return "https://api.stately.cloud" if region.nil?

      region = region.sub("aws-", "") if region.start_with?("aws-")

      "https://#{region}.aws.api.stately.cloud"
    end

    private

    # Process a list response from begin_list or continue_list
    #
    # @param resp [Stately::Db::ListResponse] the response to process
    # @return [(Array<StatelyDB::Item>, StatelyDB::Token)] the list of Items and the token
    # @api private
    # @!visibility private
    def process_list_response(resp)
      items = []
      token = nil
      resp.each do |r|
        case r.response
        when :result
          r.result.items.map do |result|
            items << @schema.unmarshal_item(stately_item: result)
          end
        when :finished
          raw_token = r.finished.token
          token = StatelyDB::Token.new(token_data: raw_token.token_data,
                                       can_continue: raw_token.can_continue,
                                       can_sync: raw_token.can_sync,
                                       schema_version_id: raw_token.schema_version_id)
        end
      end
      [items, token]
    end

    # Process a sync response from sync_list
    #
    # @param resp [Stately::Db::SyncResponse] the response to process
    # @return [StatelyDB::SyncResult] the result of the sync operation
    # @api private
    # @!visibility private
    def process_sync_response(resp)
      changed_items = []
      deleted_item_paths = []
      updated_outside_list_window_paths = []
      token = nil
      is_reset = false
      resp.each do |r|
        case r.response
        when :result
          r.result.changed_items.each do |item|
            changed_items << @schema.unmarshal_item(stately_item: item)
          end
          r.result.deleted_items.each do |item|
            deleted_item_paths << item.key_path
          end
          r.result.updated_item_keys_outside_list_window.each do |item|
            updated_outside_list_window_paths << item.key_path
          end
        when :reset
          is_reset = true
        when :finished
          raw_token = r.finished.token
          token = StatelyDB::Token.new(token_data: raw_token.token_data,
                                       can_continue: raw_token.can_continue,
                                       can_sync: raw_token.can_sync,
                                       schema_version_id: raw_token.schema_version_id)
        end
      end
      SyncResult.new(changed_items:, deleted_item_paths:, updated_outside_list_window_paths:, is_reset:, token:)
    end
  end

  # SyncResult represents the results of a sync operation.
  #
  # @attr_reader changed_items [Array<StatelyDB::Item>] the items that were changed
  # @attr_reader deleted_item_paths [Array<String>] the key paths that were deleted
  # @attr_reader updated_outside_list_window_paths [Array<String>] the key paths of
  #   items that were updated but Stately cannot tell if they were in the sync window.
  #   Treat these as deleted in most cases.
  # @attr_reader is_reset [Boolean] whether the sync operation reset the token
  # @attr_reader token [StatelyDB::Token] the token to continue from
  class SyncResult
    attr_reader :changed_items, :deleted_item_paths, :updated_outside_list_window_paths, :is_reset, :token

    # @param changed_items [Array<StatelyDB::Item>] the items that were changed
    # @param deleted_item_paths [Array<String>] the key paths that were deleted
    # @param updated_outside_list_window_paths [Array<String>] key paths for items that were updated
    #   but do not currently use the sort property that the list window is based on
    # @param is_reset [Boolean] whether the sync operation reset the token
    # @param token [StatelyDB::Token] the token to continue from
    def initialize(changed_items:, deleted_item_paths:, updated_outside_list_window_paths:, is_reset:, token:)
      @changed_items = changed_items
      @deleted_item_paths = deleted_item_paths
      @updated_outside_list_window_paths = updated_outside_list_window_paths
      @is_reset = is_reset
      @token = token
    end
  end

  # StatelyDB::Item is a base class for all StatelyDB Items. This class is provided in documentation
  # to show the expected interface for a StatelyDB Item, but in practice the SDK will return a subclass
  # of this class that is generated from the schema.
  class Item < Object
  end
end
