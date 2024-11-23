# frozen_string_literal: true

module StatelyDB
  module Transaction
    # Transaction coordinates sending requests and waiting for responses. Consumers should not need
    # to interact with this class directly, but instead use the methods provided by the StatelyDB::CoreClient.
    #
    # The example below demonstrates using a transaction, which accepts a block. The lines in the block
    # are executed within the context of the transaction. The transaction is committed when the block
    # completes successfully, OR is aborted if an exception is raised.
    #
    # @example
    #   result = client.transaction do |tx|
    #     key_path = StatelyDB::KeyPath.with('movie', 'The Shining')
    #     movie = tx.get(key_path:)
    #     tx.put(item: movie)
    #   end
    #
    class Transaction
      # Result represents the results of a transaction
      #
      # @attr_reader puts [Array<StatelyDB::Item>] the items that were put
      # @attr_reader deletes [Array<String>] the key paths that were deleted
      class Result
        # puts is an array of StatelyDB::Items that were put
        # @return [Array<StatelyDB::Item>]
        attr_reader :puts

        # deletes is an array of key paths that were deleted
        # @return [Array<String>]
        attr_reader :deletes

        # Initialize a new Result
        #
        # @param puts [Array<StatelyDB::Item>] the items that were put
        # @param deletes [Array<String>] the key paths that were deleted
        def initialize(puts:, deletes:)
          @puts = puts
          @deletes = deletes
        end
      end

      # Initialize a new Transaction
      #
      # @param stub [Stately::Db::DatabaseService::Stub] a StatelyDB gRPC stub
      # @param store_id [Integer] the StatelyDB Store to transact against
      # @param schema [StatelyDB::Schema] the schema to use for marshalling and unmarshalling Items
      def initialize(stub:, store_id:, schema:)
        @stub = stub
        @store_id = store_id
        @schema = schema
        @is_transaction_open = false

        # A queue of outbound requests
        @outgoing_requests = StatelyDB::Transaction::Queue.new
      end

      # Send a request and wait for a response
      #
      # @param req [Stately::Db::TransactionRequest] the request to send
      # @return [Stately::Db::TransactionResponse] the response
      # @api private
      # @!visibility private
      def request_response(req)
        request_only(req)
        begin
          resp = @incoming_responses.next
          if req.message_id != resp.message_id
            raise "Message ID mismatch: request #{req.message_id} != response #{resp.message_id}"
          end
          raise "Response type mismatch" if infer_response_type_from_request(req) != infer_response_type_from_response(resp)

          resp
        rescue StopIteration
          nil
        end
      end

      # Send a request and don't wait for a response
      #
      # @param req [Stately::Db::TransactionRequest] the request to send
      # @return [void] nil
      # @api private
      # @!visibility private
      def request_only(req)
        req.message_id = @outgoing_requests.next_message_id
        @outgoing_requests.push(req)
        nil
      end

      # Send a request and process all responses, until we receive a finished message. This is used for list operations.
      # Each response is processed by the block passed to this method, and the response for this method is a token.
      #
      # @param req [Stately::Db::TransactionRequest] the request to send
      # @yieldparam resp [Stately::Db::TransactionListResponse] the response
      # @return [Stately::Db::ListToken] the token
      # @example
      #   request_list_responses(req) do |resp|
      #     resp.result.items.each do |result|
      #       puts result.item.key_path
      #     end
      # @api private
      # @!visibility private
      def request_list_responses(req)
        request_only(req)
        token = nil
        loop do
          resp = @incoming_responses.next.list_results
          if resp.finished
            raw_token = resp.finished.token
            token = StatelyDB::Token.new(token_data: raw_token.token_data,
                                         can_continue: raw_token.can_continue,
                                         can_sync: raw_token.can_sync,
                                         schema_version_id: raw_token.schema_version_id)
            break
          end
          yield resp
        end
        token
      end

      # Begin a transaction. Begin is called implicitly when the block passed to transaction is called.
      # @return [void] nil
      # @api private
      # @!visibility private
      def begin
        @is_transaction_open = true
        req = Stately::Db::TransactionRequest.new(
          begin: Stately::Db::TransactionBegin.new(store_id: @store_id.to_i,
                                                   schema_version_id: @schema::SCHEMA_VERSION_ID)
        )
        request_only(req)
        @incoming_responses = @stub.transaction(@outgoing_requests)
        nil
      end

      # Commit a transaction. Commit is called implicitly when the block passed to transaction completes.
      # @return [StatelyDB::Transaction::Transaction::Result]
      # @api private
      # @!visibility private
      def commit
        req = Stately::Db::TransactionRequest.new(
          commit: Google::Protobuf::Empty.new
        )
        resp = request_response(req).finished
        @is_transaction_open = false
        Result.new(
          puts: resp.put_results.map do |result|
            @schema.unmarshal_item(stately_item: result)
          end,
          deletes: resp.delete_results.map(&:key_path)
        )
      end

      # Abort a transaction. Abort is called implicitly if an exception is raised within the block passed to transaction.
      # @return [Stately::Db::TransactionResponse]
      # @api private
      # @!visibility private
      def abort
        req = Stately::Db::TransactionRequest.new(
          abort: Google::Protobuf::Empty.new
        )
        resp = request_only(req)
        @is_transaction_open = false
        resp
      end

      # Check if a transaction is open. A transaction is open if begin has been called and commit or abort has not been called.
      #
      # @return [Boolean] true if a transaction is open
      # @api private
      # @!visibility private
      def open?
        @is_transaction_open
      end

      # Fetch Items from a StatelyDB Store at the given key_path. Note that Items need to exist before being retrieved inside a
      # transaction.
      #
      # @param key_path [String] the path to the item
      # @return [StatelyDB::Item, NilClass] the item or nil if not found
      # @raise [StatelyDB::Error::InvalidParameters] if the parameters are invalid
      # @raise [StatelyDB::Error::NotFound] if the item is not found
      #
      # @example
      #   client.data.transaction do |txn|
      #     item = txn.get("/ItemType-identifier")
      #   end
      def get(key_path)
        resp = get_batch(key_path)

        # Always return a single Item.
        resp.first
      end

      # Fetch a batch of up to 100 Items from a StatelyDB Store at the given
      # key_paths. Note that Items need to exist before being retrieved inside a
      # transaction.
      #
      # @param key_paths [String, Array<String>] the paths to the items. Max 100
      # key paths.
      # @return [Array<StatelyDB::Item>] the items
      # @raise [StatelyDB::Error::InvalidParameters] if the parameters are invalid
      # @raise [StatelyDB::Error::NotFound] if the item is not found
      #
      # Example:
      #   client.data.transaction do |txn|
      #     items = txn.get_batch("/foo", "/bar")
      #   end
      def get_batch(*key_paths)
        key_paths = Array(key_paths).flatten
        req = Stately::Db::TransactionRequest.new(
          get_items: Stately::Db::TransactionGet.new(
            gets: key_paths.map { |key_path| Stately::Db::GetItem.new(key_path: String(key_path)) }
          )
        )
        resp = request_response(req).get_results

        resp.items.map do |result|
          @schema.unmarshal_item(stately_item: result)
        end
      end

      # Put a single Item into a StatelyDB store. Results are not returned until the transaction is
      # committed and will be available in the Result object returned by commit. An identifier for
      # the item will be returned while inside the transaction block.
      #
      # @param item [StatelyDB::Item] the item to store
      # @param must_not_exist [Boolean] A condition that indicates this item must
      #   not already exist at any of its key paths. If there is already an item
      #   at one of those paths, the Put operation will fail with a
      #   "ConditionalCheckFailed" error. Note that if the item has an
      #   `initialValue` field in its key, that initial value will automatically
      #   be chosen not to conflict with existing items, so this condition only
      #   applies to key paths that do not contain the `initialValue` field.
      # @return [String, Integer] the id of the item
      #
      # @example
      #   results = client.data.transaction do |txn|
      #     txn.put(my_item)
      #   end
      #  results.puts.each do |result|
      #    puts result.key_path
      #  end
      def put(item, must_not_exist: false)
        resp = put_batch({ item:, must_not_exist: })
        resp.first
      end

      # Put a batch of up to 50 Items into a StatelyDB Store. Results are not
      # returned until the transaction is committed and will be available in the
      # Result object returned by commit. A list of identifiers for the items
      # will be returned while inside the transaction block.
      #
      # @param items [StatelyDB::Item, Array<StatelyDB::Item>] the items to store. Max
      # 50 items.
      # @return [Array<StatelyDB::UUID, String, Integer, nil>] the ids of the items
      #
      # @example
      #   results = client.data.transaction do |txn|
      #     txn.put_batch(item1, item2)
      #   end
      #  results.puts.each do |result|
      #    puts result.key_path
      #  end
      def put_batch(*items)
        puts = Array(items).flatten.map do |input|
          if input.is_a?(Hash)
            item = input[:item]
            Stately::Db::PutItem.new(
              item: item.send("marshal_stately"),
              must_not_exist: input[:must_not_exist]
            )
          else
            Stately::Db::PutItem.new(
              item: input.send("marshal_stately")
            )
          end
        end
        req = Stately::Db::TransactionRequest.new(
          put_items: Stately::Db::TransactionPut.new(
            puts:
          )
        )

        resp = request_response(req).put_ack
        resp.generated_ids.map do |generated_id|
          case generated_id.value
          when :bytes
            StatelyDB::UUID.valid_uuid?(generated_id.bytes) ? StatelyDB::UUID.parse(generated_id.bytes) : generated_id.bytes
          when :uint
            generated_id.uint
          else # rubocop:disable Style/EmptyElse
            # An empty identifier is sent in the transaction Put response if an initialValue is not set
            nil
          end
        end
      end

      # Delete up to 50 Items from a StatelyDB Store at the given key_paths. Results are not returned until the transaction is
      # committed and will be available in the Result object returned by commit.
      #
      # @param key_paths [String, Array<String>] the paths to the items. Max 50 key paths.
      # @return [void] nil
      #
      # Example:
      #   client.data.transaction do |txn|
      #     txn.delete("/ItemType-identifier", "/ItemType-identifier2")
      #   end
      def delete(*key_paths)
        key_paths = Array(key_paths).flatten
        req = Stately::Db::TransactionRequest.new(
          delete_items: Stately::Db::TransactionDelete.new(
            deletes: key_paths.map { |key_path| Stately::Db::DeleteItem.new(key_path: String(key_path)) }
          )
        )
        request_only(req)
        nil
      end

      # Begin listing Items from a StatelyDB Store at the given prefix.
      #
      # @param prefix [String] the prefix to list
      # @param limit [Integer] the maximum number of items to return
      # @param sort_property [String] the property to sort by
      # @param sort_direction [Symbol] the direction to sort by (:ascending or :descending)
      # @return [(Array<StatelyDB::Item>, Stately::Db::ListToken)] the list of Items and the token
      #
      # Example:
      #   client.data.transaction do |txn|
      #     (items, token) = txn.begin_list("/ItemType-identifier")
      #     (items, token) = txn.continue_list(token)
      #   end
      def begin_list(prefix,
                     limit: 100,
                     sort_property: nil,
                     sort_direction: :ascending)
        sort_direction = case sort_direction
                         when :ascending
                           0
                         else
                           1
                         end
        req = Stately::Db::TransactionRequest.new(
          begin_list: Stately::Db::TransactionBeginList.new(
            key_path_prefix: String(prefix),
            limit:,
            sort_property:,
            sort_direction:
          )
        )
        do_list_request_response(req)
      end

      # Continue listing Items from a StatelyDB Store using a token.
      #
      # @param token [Stately::Db::ListToken] the token to continue from
      # @param continue_direction [Symbol] the direction to continue by (:forward or :backward)
      # @return [(Array<StatelyDB::Item>, Stately::Db::ListToken)] the list of Items and the token
      #
      # Example:
      #   client.data.transaction do |txn|
      #     (items, token) = txn.begin_list("/foo")
      #     (items, token) = txn.continue_list(token)
      #   end
      def continue_list(token, continue_direction: :forward)
        continue_direction = continue_direction == :forward ? 0 : 1

        req = Stately::Db::TransactionRequest.new(
          continue_list: Stately::Db::TransactionContinueList.new(
            token_data: token.token_data,
            direction: continue_direction
          )
        )
        do_list_request_response(req)
      end

      private

      # Processes a list response from begin_list or continue_list
      #
      # @param req [Stately::Db::TransactionRequest] the request to send
      # @return [(Array<StatelyDB::Item>, Stately::Db::ListToken)] the list of Items and the token
      # @api private
      # @!visibility private
      def do_list_request_response(req)
        items = []
        token = request_list_responses(req) do |resp|
          resp.result.items.each do |list_items_result|
            items << @schema.unmarshal_item(stately_item: list_items_result)
          end
        end
        [items, token]
      end

      # We are using a oneof inside the TransactionRequest to determine the type of request. The ruby
      # generated code does not have a helper for the internal request type so we need to infer it.
      #
      # @param req [Stately::Db::TransactionRequest] the request
      # @return [Class] the response type
      # @api private
      # @!visibility private
      def infer_response_type_from_request(req)
        if req.respond_to?(:get_items)
          Stately::Db::TransactionGetResponse
        elsif req.respond_to?(:list_items)
          Stately::Db::TransactionListResponse
        else
          raise "Unknown request type or request type does not have a corresponding response type"
        end
      end

      # We are using a oneof inside the TransactionResponse to determine the type of response. The ruby
      # generated code does not have a helper for the internal response type so we need to infer it.
      #
      # @param resp [Stately::Db::TransactionResponse] the response
      # @return [Class] the response type
      # @api private
      # @!visibility private
      def infer_response_type_from_response(resp)
        if resp.respond_to?(:get_results)
          Stately::Db::TransactionGetResponse
        elsif resp.respond_to?(:list_results)
          Stately::Db::TransactionListResponse
        else
          raise "Unknown response type"
        end
      end
    end
  end
end
