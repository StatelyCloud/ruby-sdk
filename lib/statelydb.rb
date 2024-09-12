# frozen_string_literal: true

# Add the pb dir to the LOAD_PATH because generated proto imports are not relative and
# we don't want the protos polluting the main namespace.
# Tracking here: https://github.com/grpc/grpc/issues/6164
$LOAD_PATH.unshift "#{File.dirname(__FILE__)}/api"

require "api/db/service_services_pb"
require "common/auth/auth0_token_provider"
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
  # Client is a client for interacting with the Stately Cloud API.
  class Client
    # Initialize a new StatelyDB Client
    #
    # @param store_id [Integer] the StatelyDB to use for all operations with this client.
    # @param schema [Module] the schema module to use for mapping StatelyDB Items.
    # @param token_provider [Common::Auth::TokenProvider] the token provider to use for authentication.
    # @param channel [GRPC::Core::Channel] the gRPC channel to use for communication.
    def initialize(store_id: nil,
                   schema: StatelyDB::Types,
                   token_provider: Common::Auth::Auth0TokenProvider.new,
                   channel: Common::Net.new_channel)
      raise "store_id is required" if store_id.nil?
      raise "schema is required" if schema.nil?

      auth_interceptor = Common::Auth::Interceptor.new(token_provider:)
      error_interceptor = Common::ErrorInterceptor.new

      @stub = Stately::Db::DatabaseService::Stub.new(nil, nil, channel_override: channel,
                                                               interceptors: [error_interceptor, auth_interceptor])
      @store_id = store_id.to_i
      @schema = schema
      @allow_stale = false
    end

    # Set whether to allow stale results for all operations with this client. This produces a new client
    # with the allow_stale flag set.
    # @param allow_stale [Boolean] whether to allow stale results
    # @return [StatelyDB::Client] a new client with the allow_stale flag set
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

    # Fetch a batch of Items from a StatelyDB Store at the given key_paths.
    #
    # @param key_paths [String, Array<String>] the paths to the items
    # @return [Array<StatelyDB::Item>, NilClass] the items or nil if not found
    # @raise [StatelyDB::Error] if the parameters are invalid or if the item is not found
    #
    # @example
    #   client.data.get_batch("/ItemType-identifier", "/ItemType-identifier2")
    def get_batch(*key_paths)
      key_paths = Array(key_paths).flatten
      req = Stately::Db::GetRequest.new(
        store_id: @store_id,
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
        allow_stale: @allow_stale
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
        token_data: token.token_data
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
        token_data: token.token_data
      )
      resp = @stub.sync_list(req)
      process_sync_response(resp)
    end

    # Put an Item into a StatelyDB Store at the given key_path.
    #
    # @param item [StatelyDB::Item] a StatelyDB Item
    # @return [StatelyDB::Item] the item that was stored
    #
    # @example
    #   client.data.put(my_item)
    def put(item)
      resp = put_batch(item)

      # Always return a single Item.
      resp.first
    end

    # Put a batch of Items into a StatelyDB Store.
    #
    # @param items [StatelyDB::Item, Array<StatelyDB::Item>] the items to store
    # @return [Array<StatelyDB::Item>] the items that were stored
    #
    # @example
    #   client.data.put_batch(item1, item2)
    def put_batch(*items)
      items = Array(items).flatten
      req = Stately::Db::PutRequest.new(
        store_id: @store_id,
        puts: items.map do |item|
          Stately::Db::PutItem.new(
            item: item.send("marshal_stately")
          )
        end
      )
      resp = @stub.put(req)

      resp.items.map do |result|
        @schema.unmarshal_item(stately_item: result)
      end
    end

    # Delete one or more Items from a StatelyDB Store at the given key_paths.
    #
    # @param key_paths [String, Array<String>] the paths to the items
    # @raise [StatelyDB::Error::InvalidParameters] if the parameters are invalid
    # @raise [StatelyDB::Error::NotFound] if the item is not found
    # @return [void] nil
    #
    # @example
    #   client.data.delete("/ItemType-identifier", "/ItemType-identifier2")
    def delete(*key_paths)
      key_paths = Array(key_paths).flatten
      req = Stately::Db::DeleteRequest.new(
        store_id: @store_id,
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
    # @raise [StatelyDB::Error::InvalidParameters] if the parameters are invalid
    # @raise [StatelyDB::Error::NotFound] if the item is not found
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
                                       can_sync: raw_token.can_sync)
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
        when :reset
          is_reset = true
        when :finished
          raw_token = r.finished.token
          token = StatelyDB::Token.new(token_data: raw_token.token_data,
                                       can_continue: raw_token.can_continue,
                                       can_sync: raw_token.can_sync)
        end
      end
      SyncResult.new(changed_items:, deleted_item_paths:, is_reset:, token:)
    end
  end

  # SyncResult represents the results of a sync operation.
  #
  # @attr_reader changed_items [Array<StatelyDB::Item>] the items that were changed
  # @attr_reader deleted_item_paths [Array<String>] the key paths that were deleted
  # @attr_reader is_reset [Boolean] whether the sync operation reset the token
  # @attr_reader token [StatelyDB::Token] the token to continue from
  class SyncResult
    attr_reader :changed_items, :deleted_item_paths, :is_reset, :token

    # @param changed_items [Array<StatelyDB::Item>] the items that were changed
    # @param deleted_item_paths [Array<String>] the key paths that were deleted
    # @param is_reset [Boolean] whether the sync operation reset the token
    # @param token [StatelyDB::Token] the token to continue from
    def initialize(changed_items:, deleted_item_paths:, is_reset:, token:)
      @changed_items = changed_items
      @deleted_item_paths = deleted_item_paths
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
