# typed: strong
# A module for Stately Cloud auth code
module StatelyDB
  # UUID is a helper class for working with UUIDs in StatelyDB. The ruby version of a StatelyDB is a binary string,
  # and this class provides convenience methods for converting to the base16 representation specified in RFC 9562.
  # Internally this class uses the byte_string attribute to store the UUID as a string with the Encoding::ASCII_8BIT
  # encoding.
  class UUID
    # _@param_ `byte_string` — A binary-encoded string (eg: Encoding::ASCII_8BIT encoding)
    sig { params(byte_string: String).void }
    def initialize(byte_string); end

    # to_s returns the UUID as a base16 string (eg: "f4a8a24a-129d-411f-91d2-6d19d0eaa096")
    sig { returns(String) }
    def to_s; end

    # to_str returns the UUID as a base16 string (eg: "f4a8a24a-129d-411f-91d2-6d19d0eaa096")
    # 
    # Note: to_str is a type coercion method that is called by Ruby when an object is coerced to a string.
    sig { returns(String) }
    def to_str; end

    # Encodes the byte string as a url-safe base64 string with padding removed.
    sig { returns(String) }
    def to_base64; end

    # UUIDs are equal if their byte_strings are equal.
    # 
    # _@param_ `other`
    sig { params(other: StatelyDB::UUID).returns(T::Boolean) }
    def ==(other); end

    # UUIDs are sorted lexigraphically by their base16 representation.
    # 
    # _@param_ `other`
    sig { params(other: StatelyDB::UUID).returns(Integer) }
    def <=>(other); end

    # Returns true if the UUID is empty.
    sig { returns(T::Boolean) }
    def empty?; end

    # Parses a base16 string (eg: "f4a8a24a-129d-411f-91d2-6d19d0eaa096") into a UUID object.
    # The string can be the following:
    # 1. Encoded as Encoding::ASCII_8BIT (also aliased as Encoding::BINARY) and be 16 bytes long.
    # 2. A string of the form "f4a8a24a-129d-411f-91d2-6d19d0eaa096"
    # 
    # _@param_ `byte_string` — A binary-encoded string (eg: Encoding::ASCII_8BIT encoding) that is 16 bytes in length, or a base16-formatted UUID string.
    sig { params(byte_string: String).returns(StatelyDB::UUID) }
    def self.parse(byte_string); end

    # Not all bytes values in StatelyDB are UUIDs. This method checks if a byte string is a valid UUID.
    # 
    # _@param_ `byte_string` — A binary-encoded string (eg: Encoding::ASCII_8BIT encoding)
    sig { params(byte_string: String).returns(T::Boolean) }
    def self.valid_uuid?(byte_string); end

    # Returns the value of attribute byte_string.
    sig { returns(T.untyped) }
    attr_accessor :byte_string
  end

  # The Error class contains common StatelyDB error types.
  class Error < StandardError
    # _@param_ `message`
    # 
    # _@param_ `code`
    # 
    # _@param_ `stately_code`
    # 
    # _@param_ `cause`
    sig do
      params(
        message: String,
        code: T.nilable(Integer),
        stately_code: T.nilable(String),
        cause: T.nilable(Exception)
      ).void
    end
    def initialize(message, code: nil, stately_code: nil, cause: nil); end

    # Convert any exception into a StatelyDB::Error.
    # 
    # _@param_ `error`
    sig { params(error: Exception).returns(StatelyDB::Error) }
    def self.from(error); end

    # Turn this error's gRPC status code into a human-readable string. e.g. 3 -> "InvalidArgument"
    sig { returns(String) }
    def code_string; end

    # Turn a gRPC status code into a human-readable string. e.g. 3 -> "InvalidArgument"
    # 
    # _@param_ `code`
    sig { params(code: Integer).returns(String) }
    def self.grpc_code_to_string(code); end

    # The gRPC/Connect Code for this error.
    sig { returns(Integer) }
    attr_reader :code

    # The more fine-grained Stately error code, which is a human-readable string.
    sig { returns(String) }
    attr_reader :stately_code

    # The upstream cause of the error, if available.
    sig { returns(Exception) }
    attr_reader :cause
  end

  # The Token type contains a continuation token for list and sync operations along with metadata about the ability
  # to sync or continue listing based on the last operation performed.
  # 
  # Ths StatelyDB SDK vends this Token type for list and sync operations.
  # Consumers should not need to construct this type directly.
  class Token
    # _@param_ `token_data`
    # 
    # _@param_ `can_continue`
    # 
    # _@param_ `can_sync`
    # 
    # _@param_ `schema_version_id`
    sig do
      params(
        token_data: String,
        can_continue: T::Boolean,
        can_sync: T::Boolean,
        schema_version_id: Integer
      ).void
    end
    def initialize(token_data:, can_continue:, can_sync:, schema_version_id:); end

    # Returns true if the list operation can be continued, otherwise false.
    sig { returns(T::Boolean) }
    def can_continue?; end

    # Returns true if the sync operation can be continued, otherwise false.
    sig { returns(T::Boolean) }
    def can_sync?; end

    # Returns the value of attribute token_data.
    sig { returns(T.untyped) }
    attr_accessor :token_data

    # Returns the schema version ID associated with the token.
    sig { returns(Integer) }
    attr_reader :schema_version_id
  end

  # KeyPath is a helper class for constructing key paths.
  class KeyPath
    sig { void }
    def initialize; end

    # Appends a new path segment.
    # 
    # _@param_ `namespace`
    # 
    # _@param_ `identifier`
    sig { params(namespace: String, identifier: T.nilable(T.any(String, StatelyDB::UUID, T.untyped))).returns(KeyPath) }
    def with(namespace, identifier = nil); end

    sig { returns(String) }
    def to_str; end

    sig { returns(String) }
    def inspect; end

    sig { returns(String) }
    def to_s; end

    # Appends a new path segment.
    # 
    # _@param_ `namespace`
    # 
    # _@param_ `identifier`
    # 
    # ```ruby
    # keypath = KeyPath.with("genres", "rock").with("artists", "the-beatles")
    # ```
    sig { params(namespace: String, identifier: T.nilable(T.any(String, StatelyDB::UUID, T.untyped))).returns(KeyPath) }
    def self.with(namespace, identifier = nil); end

    # If the value is a binary string, encode it as a url-safe base64 string with padding removed.
    # 
    # _@param_ `value` — The value to convert to a key id.
    sig { params(value: T.any(String, StatelyDB::UUID, T.untyped)).returns(String) }
    def self.to_key_id(value); end
  end

  # CoreClient is a low level client for interacting with the Stately Cloud API.
  # This client shouldn't be used directly in most cases. Instead, use the generated
  # client for your schema.
  class CoreClient
    # Initialize a new StatelyDB CoreClient
    # 
    # _@param_ `store_id` — the StatelyDB to use for all operations with this client.
    # 
    # _@param_ `schema` — the generated Schema module to use for mapping StatelyDB Items.
    # 
    # _@param_ `token_provider` — the token provider to use for authentication.
    # 
    # _@param_ `endpoint` — the endpoint to connect to.
    # 
    # _@param_ `region` — the region to connect to.
    # 
    # _@param_ `no_auth` — Indicates that the client should not attempt to get an auth token. This is used when talking to the Stately BYOC Data Plane on localhost.
    sig do
      params(
        store_id: Integer,
        schema: Module,
        token_provider: Common::Auth::TokenProvider,
        endpoint: T.nilable(String),
        region: T.nilable(String),
        no_auth: T::Boolean
      ).void
    end
    def initialize(store_id:, schema:, token_provider: Common::Auth::AuthTokenProvider.new, endpoint: nil, region: nil, no_auth: false); end

    # _@return_ — nil
    sig { void }
    def close; end

    # Set whether to allow stale results for all operations with this client. This produces a new client
    # with the allow_stale flag set.
    # 
    # _@param_ `allow_stale` — whether to allow stale results
    # 
    # _@return_ — a new client with the allow_stale flag set
    # 
    # ```ruby
    # client.with_allow_stale(true).get("/ItemType-identifier")
    # ```
    sig { params(allow_stale: T::Boolean).returns(T.self_type) }
    def with_allow_stale(allow_stale); end

    # Fetch a single Item from a StatelyDB Store at the given key_path.
    # 
    # _@param_ `key_path` — the path to the item
    # 
    # _@return_ — the Item or nil if not found
    # 
    # ```ruby
    # client.get("/ItemType-identifier")
    # ```
    sig { params(key_path: String).returns(T.any(StatelyDB::Item, NilClass)) }
    def get(key_path); end

    # Fetch a batch of up to 100 Items from a StatelyDB Store at the given key_paths.
    # 
    # _@param_ `key_paths` — the paths to the items. Max 100 key paths.
    # 
    # _@return_ — the items or nil if not found
    # 
    # ```ruby
    # client.data.get_batch("/ItemType-identifier", "/ItemType-identifier2")
    # ```
    sig { params(key_paths: T.any(String, T::Array[String])).returns(T.any(T::Array[StatelyDB::Item], NilClass)) }
    def get_batch(*key_paths); end

    # Begin listing Items from a StatelyDB Store at the given prefix.
    # 
    # _@param_ `prefix` — the prefix to list
    # 
    # _@param_ `limit` — the maximum number of items to return
    # 
    # _@param_ `sort_property` — the property to sort by
    # 
    # _@param_ `sort_direction` — the direction to sort by (:ascending or :descending)
    # 
    # _@return_ — the list of Items and the token
    # 
    # ```ruby
    # client.data.begin_list("/ItemType-identifier", limit: 10, sort_direction: :ascending)
    # ```
    sig do
      params(
        prefix: String,
        limit: Integer,
        sort_property: T.nilable(String),
        sort_direction: Symbol
      ).returns(T.any(T::Array[StatelyDB::Item], StatelyDB::Token))
    end
    def begin_list(prefix, limit: 100, sort_property: nil, sort_direction: :ascending); end

    # Continue listing Items from a StatelyDB Store using a token.
    # 
    # _@param_ `token` — the token to continue from
    # 
    # _@return_ — the list of Items and the token
    # 
    # ```ruby
    # (items, token) = client.data.begin_list("/ItemType-identifier")
    # client.data.continue_list(token)
    # ```
    sig { params(token: StatelyDB::Token).returns(T.any(T::Array[StatelyDB::Item], StatelyDB::Token)) }
    def continue_list(token); end

    # Sync a list of Items from a StatelyDB Store.
    # 
    # _@param_ `token` — the token to sync from
    # 
    # _@return_ — the result of the sync operation
    # 
    # ```ruby
    # (items, token) = client.data.begin_list("/ItemType-identifier")
    # client.data.sync_list(token)
    # ```
    sig { params(token: StatelyDB::Token).returns(StatelyDB::SyncResult) }
    def sync_list(token); end

    # Put an Item into a StatelyDB Store at the given key_path.
    # 
    # _@param_ `item` — a StatelyDB Item
    # 
    # _@param_ `must_not_exist` — A condition that indicates this item must not already exist at any of its key paths. If there is already an item at one of those paths, the Put operation will fail with a "ConditionalCheckFailed" error. Note that if the item has an `initialValue` field in its key, that initial value will automatically be chosen not to conflict with existing items, so this condition only applies to key paths that do not contain the `initialValue` field.
    # 
    # _@param_ `overwrite_metadata_timestamps` — If set to true, the server will set the `createdAtTime` and/or `lastModifiedAtTime` fields based on the current values in this item (assuming you've mapped them to a field using `fromMetadata`). Without this, those fields are always ignored and the server sets them to the appropriate times. This option can be useful when migrating data from another system.
    # 
    # _@return_ — the item that was stored
    # 
    # client.data.put(my_item)
    # ```ruby
    # ```
    # 
    # client.data.put(my_item, must_not_exist: true)
    # ```ruby
    # ```
    sig { params(item: StatelyDB::Item, must_not_exist: T::Boolean, overwrite_metadata_timestamps: T::Boolean).returns(StatelyDB::Item) }
    def put(item, must_not_exist: false, overwrite_metadata_timestamps: false); end

    # Put a batch of up to 50 Items into a StatelyDB Store.
    # 
    # Max 50 items.
    # 
    # _@param_ `items` — the items to store.
    # 
    # _@return_ — the items that were stored
    # 
    # ```ruby
    # client.data.put_batch(item1, item2)
    # ```
    # 
    # ```ruby
    # client.data.put_batch({ item: item1, must_not_exist: true }, item2)
    # ```
    sig { params(items: T.any(StatelyDB::Item, T::Array[StatelyDB::Item])).returns(T::Array[StatelyDB::Item]) }
    def put_batch(*items); end

    # Delete up to 50 Items from a StatelyDB Store at the given key_paths.
    # 
    # _@param_ `key_paths` — the paths to the items. Max 50 key paths.
    # 
    # _@return_ — nil
    # 
    # ```ruby
    # client.data.delete("/ItemType-identifier", "/ItemType-identifier2")
    # ```
    sig { params(key_paths: T.any(String, T::Array[String])).void }
    def delete(*key_paths); end

    # Transaction takes a block and executes the block within a transaction.
    # If the block raises an exception, the transaction is rolled back.
    # If the block completes successfully, the transaction is committed.
    # 
    # _@return_ — the result of the transaction
    # 
    # ```ruby
    # client.data.transaction do |txn|
    #   txn.put(item: my_item)
    #   txn.put(item: another_item)
    # end
    # ```
    sig { returns(StatelyDB::Transaction::Transaction::Result) }
    def transaction; end

    # Construct the API endpoint from the region and endpoint.
    # If the endpoint is provided, it will be returned as-is.
    # If the region is provided and the endpoint is not,
    # then the region-specific endpoint will be returned.
    # If neither the region nor the endpoint is provided,
    # then the default endpoint will be returned.
    # 
    # _@param_ `endpoint` — the endpoint to connect to
    # 
    # _@param_ `region` — the region to connect to
    # 
    # _@return_ — the constructed endpoint
    sig { params(endpoint: T.nilable(String), region: T.nilable(Region)).returns(String) }
    def self.make_endpoint(endpoint: nil, region: nil); end

    # Process a list response from begin_list or continue_list
    # 
    # _@param_ `resp` — the response to process
    # 
    # _@return_ — the list of Items and the token
    sig { params(resp: Stately::Db::ListResponse).returns([T::Array[StatelyDB::Item], StatelyDB::Token]) }
    def process_list_response(resp); end

    # Process a sync response from sync_list
    # 
    # _@param_ `resp` — the response to process
    # 
    # _@return_ — the result of the sync operation
    sig { params(resp: Stately::Db::SyncResponse).returns(StatelyDB::SyncResult) }
    def process_sync_response(resp); end
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
    # _@param_ `changed_items` — the items that were changed
    # 
    # _@param_ `deleted_item_paths` — the key paths that were deleted
    # 
    # _@param_ `updated_outside_list_window_paths` — key paths for items that were updated but do not currently use the sort property that the list window is based on
    # 
    # _@param_ `is_reset` — whether the sync operation reset the token
    # 
    # _@param_ `token` — the token to continue from
    sig do
      params(
        changed_items: T::Array[StatelyDB::Item],
        deleted_item_paths: T::Array[String],
        updated_outside_list_window_paths: T::Array[String],
        is_reset: T::Boolean,
        token: StatelyDB::Token
      ).void
    end
    def initialize(changed_items:, deleted_item_paths:, updated_outside_list_window_paths:, is_reset:, token:); end

    # the items that were changed
    sig { returns(T::Array[StatelyDB::Item]) }
    attr_reader :changed_items

    # the key paths that were deleted
    sig { returns(T::Array[String]) }
    attr_reader :deleted_item_paths

    # the key paths of
    # items that were updated but Stately cannot tell if they were in the sync window.
    # Treat these as deleted in most cases.
    sig { returns(T::Array[String]) }
    attr_reader :updated_outside_list_window_paths

    # whether the sync operation reset the token
    sig { returns(T::Boolean) }
    attr_reader :is_reset

    # the token to continue from
    sig { returns(StatelyDB::Token) }
    attr_reader :token
  end

  # StatelyDB::Item is a base class for all StatelyDB Items. This class is provided in documentation
  # to show the expected interface for a StatelyDB Item, but in practice the SDK will return a subclass
  # of this class that is generated from the schema.
  class Item
  end

  module Common
    # A module for Stately Cloud networking code
    module Net
      # Create a new gRPC channel
      # 
      # _@param_ `endpoint` — The endpoint to connect to
      # 
      # _@return_ — The new channel
      sig { params(endpoint: String).returns(GRPC::Core::Channel) }
      def self.new_channel(endpoint:); end
    end

    # A module for Stately Cloud auth code
    module Auth
      # GRPC interceptor to authenticate against Stately and append bearer tokens to outgoing requests
      class Interceptor < GRPC::ClientInterceptor
        # _@param_ `token_provider` — The token provider to use for authentication
        sig { params(token_provider: TokenProvider).void }
        def initialize(token_provider: AuthTokenProvider.new); end

        # gRPC client unary interceptor
        # 
        # _@param_ `request` — The request object
        # 
        # _@param_ `call` — The active call object
        # 
        # _@param_ `method` — The method being called
        # 
        # _@param_ `metadata` — The metadata hash
        # 
        # _@return_ — The response object
        sig do
          params(
            request: Object,
            call: GRPC::ActiveCall,
            method: Symbol,
            metadata: T::Hash[T.untyped, T.untyped]
          ).returns(Object)
        end
        def request_response(request:, call:, method:, metadata:); end

        # gRPC client streaming interceptor
        # 
        # _@param_ `requests` — The list of requests
        # 
        # _@param_ `call` — The active call object
        # 
        # _@param_ `method` — The method being called
        # 
        # _@param_ `metadata` — The metadata hash
        # 
        # _@return_ — The response enumerator
        sig do
          params(
            requests: T::Enumerable[T.untyped],
            call: GRPC::ActiveCall,
            method: Symbol,
            metadata: T::Hash[T.untyped, T.untyped]
          ).returns(T::Enumerator[T.untyped])
        end
        def client_streamer(requests:, call:, method:, metadata:); end

        # gRPC  server streaming interceptor
        # 
        # _@param_ `request` — The request object
        # 
        # _@param_ `call` — The active call object
        # 
        # _@param_ `method` — The method being called
        # 
        # _@param_ `metadata` — The metadata hash
        # 
        # _@return_ — The response enumerator
        sig do
          params(
            request: Object,
            call: GRPC::ActiveCall,
            method: Symbol,
            metadata: T::Hash[T.untyped, T.untyped]
          ).returns(T::Enumerator[T.untyped])
        end
        def server_streamer(request:, call:, method:, metadata:); end

        # gRPC bidirectional streaming interceptor
        # 
        # _@param_ `requests` — The list of requests
        # 
        # _@param_ `call` — The active call object
        # 
        # _@param_ `method` — The method being called
        # 
        # _@param_ `metadata` — The metadata hash
        # 
        # _@return_ — The response enumerator
        sig do
          params(
            requests: T::Enumerable[T.untyped],
            call: GRPC::ActiveCall,
            method: Symbol,
            metadata: T::Hash[T.untyped, T.untyped]
          ).returns(T::Enumerator[T.untyped])
        end
        def bidi_streamer(requests:, call:, method:, metadata:); end

        # Adds a JWT to the metadata hash
        # 
        # _@param_ `metadata` — The metadata hash
        sig { params(metadata: T::Hash[T.untyped, T.untyped]).void }
        def add_jwt_to_grpc_request(metadata:); end
      end

      # Result from a token fetch operation
      class TokenResult
        # Create a new TokenResult
        # 
        # _@param_ `token` — The access token
        # 
        # _@param_ `expires_in_secs` — The number of seconds until the token expires
        sig { params(token: String, expires_in_secs: Integer).void }
        def initialize(token:, expires_in_secs:); end

        # Returns the value of attribute token.
        sig { returns(T.untyped) }
        attr_reader :token

        # Returns the value of attribute expires_in_secs.
        sig { returns(T.untyped) }
        attr_reader :expires_in_secs
      end

      # TokenFetcher is an abstract base class that should be extended
      # for individual token fetcher implementations
      class TokenFetcher
        # Get the current access token
        # 
        # _@return_ — The fetched TokenResult
        sig { returns(TokenResult) }
        def fetch; end

        # Close the token provider and kill any background operations
        sig { returns(T.untyped) }
        def close; end
      end

      # StatelyAccessTokenFetcher is a TokenFetcher that fetches tokens from the StatelyDB API
      class StatelyAccessTokenFetcher < StatelyDB::Common::Auth::TokenFetcher
        NON_RETRYABLE_ERRORS = T.let([
  GRPC::Core::StatusCodes::UNAUTHENTICATED,
  GRPC::Core::StatusCodes::PERMISSION_DENIED,
  GRPC::Core::StatusCodes::NOT_FOUND,
  GRPC::Core::StatusCodes::UNIMPLEMENTED,
  GRPC::Core::StatusCodes::INVALID_ARGUMENT
].freeze, T.untyped)
        RETRY_ATTEMPTS = T.let(10, T.untyped)

        # _@param_ `endpoint` — The endpoint of the OAuth server
        # 
        # _@param_ `access_key` — The StatelyDB access key credential
        # 
        # _@param_ `base_retry_backoff_secs` — The base backoff time in seconds
        sig { params(endpoint: String, access_key: String, base_retry_backoff_secs: Float).void }
        def initialize(endpoint:, access_key:, base_retry_backoff_secs:); end

        # Fetch a new token from the StatelyDB API
        # 
        # _@return_ — The fetched TokenResult
        sig { returns(TokenResult) }
        def fetch; end

        sig { returns(T.untyped) }
        def close; end

        # Check if an error is retryable
        # 
        # _@param_ `err` — The error to check
        # 
        # _@return_ — True if the error is retryable
        sig { params(err: StatelyDB::Error).returns(T::Boolean) }
        def self.retryable_error?(err); end
      end

      # TokenProvider is an abstract base class that should be extended
      # for individual token provider implementations
      class TokenProvider
        # Get the current access token
        # 
        # _@param_ `force` — Whether to force a refresh of the token
        # 
        # _@return_ — The current access token
        sig { params(force: T::Boolean).returns(String) }
        def get_token(force: false); end

        # Close the token provider and kill any background operations
        sig { returns(T.untyped) }
        def close; end
      end

      # AuthTokenProvider is an implementation of the TokenProvider abstract base class
      # which vends tokens from the StatelyDB auth API.
      # It will default to using the value of `STATELY_ACCESS_KEY` if
      # no credentials are explicitly passed and will throw an error if no credentials are found.
      class AuthTokenProvider < StatelyDB::Common::Auth::TokenProvider
        # _@param_ `endpoint` — The endpoint of the auth server
        # 
        # _@param_ `access_key` — The StatelyDB access key credential
        # 
        # _@param_ `base_retry_backoff_secs` — The base retry backoff in seconds
        sig { params(endpoint: String, access_key: String, base_retry_backoff_secs: Float).void }
        def initialize(endpoint: "https://api.stately.cloud", access_key: ENV.fetch("STATELY_ACCESS_KEY", nil), base_retry_backoff_secs: 1); end

        # Close the token provider and kill any background operations
        # This just invokes the close method on the actor which should do the cleanup
        sig { returns(T.untyped) }
        def close; end

        # Get the current access token
        # 
        # _@return_ — The current access token
        sig { params(force: T::Boolean).returns(String) }
        def get_token(force: false); end

        # Actor for managing the token refresh
        # This is designed to be used with Async::Actor and run on a dedicated thread.
        class Actor
          # _@param_ `endpoint` — The endpoint of the OAuth server
          # 
          # _@param_ `access_key` — The StatelyDB access key credential
          # 
          # _@param_ `base_retry_backoff_secs` — The base retry backoff in seconds
          sig { params(endpoint: String, access_key: String, base_retry_backoff_secs: Float).void }
          def initialize(endpoint:, access_key:, base_retry_backoff_secs:); end

          # Initialize the actor. This runs on the actor thread which means
          # we can dispatch async operations here.
          sig { returns(T.untyped) }
          def init; end

          # Close the token provider and kill any background operations
          sig { returns(T.untyped) }
          def close; end

          # Get the current access token
          # 
          # _@param_ `force` — Whether to force a refresh of the token
          # 
          # _@return_ — The current access token
          sig { params(force: T::Boolean).returns(String) }
          def get_token(force: false); end

          # Get the current access token and whether it is valid
          # 
          # _@return_ — The current access token and whether it is valid
          sig { returns(T::Array[T.untyped]) }
          def valid_access_token; end

          # Refresh the access token
          # 
          # _@return_ — A task that will resolve to the new access token
          sig { returns(Task) }
          def refresh_token; end

          # Refresh the access token implementation
          # 
          # _@return_ — The new access token
          sig { returns(String) }
          def refresh_token_impl; end
        end

        # Persistent state for the token provider
        class TokenState
          # Create a new TokenState
          # 
          # _@param_ `token` — The access token
          # 
          # _@param_ `expires_at_unix_secs` — The unix timestamp when the token expires
          sig { params(token: String, expires_at_unix_secs: Integer).void }
          def initialize(token:, expires_at_unix_secs:); end

          # Returns the value of attribute token.
          sig { returns(T.untyped) }
          attr_reader :token

          # Returns the value of attribute expires_at_unix_secs.
          sig { returns(T.untyped) }
          attr_reader :expires_at_unix_secs
        end
      end
    end

    # GRPC interceptor to convert errors to StatelyDB::Error
    class ErrorInterceptor < GRPC::ClientInterceptor
      # client unary interceptor
      sig do
        params(
          request: T.untyped,
          call: T.untyped,
          method: T.untyped,
          metadata: T.untyped
        ).returns(T.untyped)
      end
      def request_response(request:, call:, method:, metadata:); end

      # client streaming interceptor
      sig do
        params(
          requests: T.untyped,
          call: T.untyped,
          method: T.untyped,
          metadata: T.untyped
        ).returns(T.untyped)
      end
      def client_streamer(requests:, call:, method:, metadata:); end

      # server streaming interceptor
      sig do
        params(
          request: T.untyped,
          call: T.untyped,
          method: T.untyped,
          metadata: T.untyped
        ).returns(T.untyped)
      end
      def server_streamer(request:, call:, method:, metadata:); end

      # bidirectional streaming interceptor
      sig do
        params(
          requests: T.untyped,
          call: T.untyped,
          method: T.untyped,
          metadata: T.untyped
        ).returns(T.untyped)
      end
      def bidi_streamer(requests:, call:, method:, metadata:); end
    end
  end

  module Transaction
    # TransactionQueue is a wrapper around Thread::Queue that implements Enumerable
    class Queue < Thread::Queue
      sig { void }
      def initialize; end

      # next_message_id returns the next message ID, which is the current size of the queue + 1.
      # This value is consumed by the StatelyDB transaction as a monotonically increasing MessageID.
      sig { returns(Integer) }
      def next_message_id; end

      # Iterates over each element in the queue, yielding each element to the given block.
      sig { void }
      def each; end

      # Iterates over each item in the queue, yielding each item to the given block.
      sig { void }
      def each_item; end

      # _@return_ — The ID of the last message, or nil if there is no message.
      sig { returns(T.nilable(Integer)) }
      attr_reader :last_message_id
    end

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
    class Transaction
      # Initialize a new Transaction
      # 
      # _@param_ `stub` — a StatelyDB gRPC stub
      # 
      # _@param_ `store_id` — the StatelyDB Store to transact against
      # 
      # _@param_ `schema` — the schema to use for marshalling and unmarshalling Items
      sig { params(stub: Stately::Db::DatabaseService::Stub, store_id: Integer, schema: StatelyDB::Schema).void }
      def initialize(stub:, store_id:, schema:); end

      # Send a request and wait for a response
      # 
      # _@param_ `req` — the request to send
      # 
      # _@return_ — the response
      sig { params(req: Stately::Db::TransactionRequest).returns(Stately::Db::TransactionResponse) }
      def request_response(req); end

      # Send a request and don't wait for a response
      # 
      # _@param_ `req` — the request to send
      # 
      # _@return_ — nil
      sig { params(req: Stately::Db::TransactionRequest).void }
      def request_only(req); end

      # Send a request and process all responses, until we receive a finished message. This is used for list operations.
      # Each response is processed by the block passed to this method, and the response for this method is a token.
      # 
      # _@param_ `req` — the request to send
      # 
      # _@return_ — the token
      # 
      # ```ruby
      # request_list_responses(req) do |resp|
      #   resp.result.items.each do |result|
      #     puts result.item.key_path
      #   end
      # ```
      sig { params(req: Stately::Db::TransactionRequest, blk: T.proc.params(resp: Stately::Db::TransactionListResponse).void).returns(Stately::Db::ListToken) }
      def request_list_responses(req, &blk); end

      # Begin a transaction. Begin is called implicitly when the block passed to transaction is called.
      # 
      # _@return_ — nil
      sig { void }
      def begin; end

      # Commit a transaction. Commit is called implicitly when the block passed to transaction completes.
      sig { returns(StatelyDB::Transaction::Transaction::Result) }
      def commit; end

      # Abort a transaction. Abort is called implicitly if an exception is raised within the block passed to transaction.
      sig { returns(Stately::Db::TransactionResponse) }
      def abort; end

      # Check if a transaction is open. A transaction is open if begin has been called and commit or abort has not been called.
      # 
      # _@return_ — true if a transaction is open
      sig { returns(T::Boolean) }
      def open?; end

      # Fetch Items from a StatelyDB Store at the given key_path. Note that Items need to exist before being retrieved inside a
      # transaction.
      # 
      # _@param_ `key_path` — the path to the item
      # 
      # _@return_ — the item or nil if not found
      # 
      # ```ruby
      # client.data.transaction do |txn|
      #   item = txn.get("/ItemType-identifier")
      # end
      # ```
      sig { params(key_path: String).returns(T.any(StatelyDB::Item, NilClass)) }
      def get(key_path); end

      # Fetch a batch of up to 100 Items from a StatelyDB Store at the given
      # key_paths. Note that Items need to exist before being retrieved inside a
      # transaction.
      # 
      # key paths.
      # Example:
      #   client.data.transaction do |txn|
      #     items = txn.get_batch("/foo", "/bar")
      #   end
      # 
      # _@param_ `key_paths` — the paths to the items. Max 100
      # 
      # _@return_ — the items
      sig { params(key_paths: T.any(String, T::Array[String])).returns(T::Array[StatelyDB::Item]) }
      def get_batch(*key_paths); end

      # Put a single Item into a StatelyDB store. Results are not returned until the transaction is
      # committed and will be available in the Result object returned by commit. An identifier for
      # the item will be returned while inside the transaction block.
      # 
      #  results.puts.each do |result|
      #    puts result.key_path
      #  end
      # 
      # _@param_ `item` — the item to store
      # 
      # _@param_ `must_not_exist` — A condition that indicates this item must not already exist at any of its key paths. If there is already an item at one of those paths, the Put operation will fail with a "ConditionalCheckFailed" error. Note that if the item has an `initialValue` field in its key, that initial value will automatically be chosen not to conflict with existing items, so this condition only applies to key paths that do not contain the `initialValue` field.
      # 
      # _@param_ `overwrite_metadata_timestamps` — If set to true, the server will set the `createdAtTime` and/or `lastModifiedAtTime` fields based on the current values in this item (assuming you've mapped them to a field using `fromMetadata`). Without this, those fields are always ignored and the server sets them to the appropriate times. This option can be useful when migrating data from another system.
      # 
      # _@return_ — the id of the item
      # 
      # ```ruby
      # results = client.data.transaction do |txn|
      #   txn.put(my_item)
      # end
      # ```
      sig { params(item: StatelyDB::Item, must_not_exist: T::Boolean, overwrite_metadata_timestamps: T::Boolean).returns(T.any(String, Integer)) }
      def put(item, must_not_exist: false, overwrite_metadata_timestamps: false); end

      # Put a batch of up to 50 Items into a StatelyDB Store. Results are not
      # returned until the transaction is committed and will be available in the
      # Result object returned by commit. A list of identifiers for the items
      # will be returned while inside the transaction block.
      # 
      # 50 items.
      #  results.puts.each do |result|
      #    puts result.key_path
      #  end
      # 
      # _@param_ `items` — the items to store. Max
      # 
      # _@return_ — the ids of the items
      # 
      # ```ruby
      # results = client.data.transaction do |txn|
      #   txn.put_batch(item1, item2)
      # end
      # ```
      sig { params(items: T.any(StatelyDB::Item, T::Array[StatelyDB::Item])).returns(T::Array[T.any(StatelyDB::UUID, String, Integer, NilClass)]) }
      def put_batch(*items); end

      # Delete up to 50 Items from a StatelyDB Store at the given key_paths. Results are not returned until the transaction is
      # committed and will be available in the Result object returned by commit.
      # 
      # Example:
      #   client.data.transaction do |txn|
      #     txn.delete("/ItemType-identifier", "/ItemType-identifier2")
      #   end
      # 
      # _@param_ `key_paths` — the paths to the items. Max 50 key paths.
      # 
      # _@return_ — nil
      sig { params(key_paths: T.any(String, T::Array[String])).void }
      def delete(*key_paths); end

      # Begin listing Items from a StatelyDB Store at the given prefix.
      # 
      # Example:
      #   client.data.transaction do |txn|
      #     (items, token) = txn.begin_list("/ItemType-identifier")
      #     (items, token) = txn.continue_list(token)
      #   end
      # 
      # _@param_ `prefix` — the prefix to list
      # 
      # _@param_ `limit` — the maximum number of items to return
      # 
      # _@param_ `sort_property` — the property to sort by
      # 
      # _@param_ `sort_direction` — the direction to sort by (:ascending or :descending)
      # 
      # _@return_ — the list of Items and the token
      sig do
        params(
          prefix: String,
          limit: Integer,
          sort_property: T.nilable(String),
          sort_direction: Symbol
        ).returns([T::Array[StatelyDB::Item], Stately::Db::ListToken])
      end
      def begin_list(prefix, limit: 100, sort_property: nil, sort_direction: :ascending); end

      # Continue listing Items from a StatelyDB Store using a token.
      # 
      # Example:
      #   client.data.transaction do |txn|
      #     (items, token) = txn.begin_list("/foo")
      #     (items, token) = txn.continue_list(token)
      #   end
      # 
      # _@param_ `token` — the token to continue from
      # 
      # _@param_ `continue_direction` — the direction to continue by (:forward or :backward)
      # 
      # _@return_ — the list of Items and the token
      sig { params(token: Stately::Db::ListToken, continue_direction: Symbol).returns([T::Array[StatelyDB::Item], Stately::Db::ListToken]) }
      def continue_list(token, continue_direction: :forward); end

      # Processes a list response from begin_list or continue_list
      # 
      # _@param_ `req` — the request to send
      # 
      # _@return_ — the list of Items and the token
      sig { params(req: Stately::Db::TransactionRequest).returns([T::Array[StatelyDB::Item], Stately::Db::ListToken]) }
      def do_list_request_response(req); end

      # We are using a oneof inside the TransactionRequest to determine the type of request. The ruby
      # generated code does not have a helper for the internal request type so we need to infer it.
      # 
      # _@param_ `req` — the request
      # 
      # _@return_ — the response type
      sig { params(req: Stately::Db::TransactionRequest).returns(Class) }
      def infer_response_type_from_request(req); end

      # We are using a oneof inside the TransactionResponse to determine the type of response. The ruby
      # generated code does not have a helper for the internal response type so we need to infer it.
      # 
      # _@param_ `resp` — the response
      # 
      # _@return_ — the response type
      sig { params(resp: Stately::Db::TransactionResponse).returns(Class) }
      def infer_response_type_from_response(resp); end

      # Result represents the results of a transaction
      # 
      # @attr_reader puts [Array<StatelyDB::Item>] the items that were put
      # @attr_reader deletes [Array<String>] the key paths that were deleted
      class Result
        # Initialize a new Result
        # 
        # _@param_ `puts` — the items that were put
        # 
        # _@param_ `deletes` — the key paths that were deleted
        sig { params(puts: T::Array[StatelyDB::Item], deletes: T::Array[String]).void }
        def initialize(puts:, deletes:); end

        # puts is an array of StatelyDB::Items that were put
        sig { returns(T::Array[StatelyDB::Item]) }
        attr_reader :puts

        # deletes is an array of key paths that were deleted
        sig { returns(T::Array[String]) }
        attr_reader :deletes
      end
    end
  end
end

module Stately
  module Db
    GetRequest = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.GetRequest").msgclass, T.untyped)
    GetItem = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.GetItem").msgclass, T.untyped)
    GetResponse = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.GetResponse").msgclass, T.untyped)
    PutRequest = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.PutRequest").msgclass, T.untyped)
    PutItem = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.PutItem").msgclass, T.untyped)
    PutResponse = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.PutResponse").msgclass, T.untyped)
    Item = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.Item").msgclass, T.untyped)
    BeginListRequest = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.BeginListRequest").msgclass, T.untyped)
    ListResponse = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.ListResponse").msgclass, T.untyped)
    ListPartialResult = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.ListPartialResult").msgclass, T.untyped)
    ListFinished = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.ListFinished").msgclass, T.untyped)
    SortDirection = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.SortDirection").enummodule, T.untyped)
    DeleteRequest = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.DeleteRequest").msgclass, T.untyped)
    DeleteItem = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.DeleteItem").msgclass, T.untyped)
    DeleteResult = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.DeleteResult").msgclass, T.untyped)
    DeleteResponse = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.DeleteResponse").msgclass, T.untyped)
    SyncListRequest = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.SyncListRequest").msgclass, T.untyped)
    SyncListResponse = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.SyncListResponse").msgclass, T.untyped)
    SyncListReset = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.SyncListReset").msgclass, T.untyped)
    SyncListPartialResponse = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.SyncListPartialResponse").msgclass, T.untyped)
    DeletedItem = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.DeletedItem").msgclass, T.untyped)
    ListToken = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.ListToken").msgclass, T.untyped)
    TransactionRequest = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.TransactionRequest").msgclass, T.untyped)
    TransactionResponse = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.TransactionResponse").msgclass, T.untyped)
    TransactionBegin = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.TransactionBegin").msgclass, T.untyped)
    TransactionGet = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.TransactionGet").msgclass, T.untyped)
    TransactionBeginList = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.TransactionBeginList").msgclass, T.untyped)
    TransactionContinueList = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.TransactionContinueList").msgclass, T.untyped)
    TransactionPut = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.TransactionPut").msgclass, T.untyped)
    TransactionDelete = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.TransactionDelete").msgclass, T.untyped)
    TransactionGetResponse = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.TransactionGetResponse").msgclass, T.untyped)
    GeneratedID = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.GeneratedID").msgclass, T.untyped)
    TransactionPutAck = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.TransactionPutAck").msgclass, T.untyped)
    TransactionListResponse = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.TransactionListResponse").msgclass, T.untyped)
    TransactionFinished = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.TransactionFinished").msgclass, T.untyped)
    ContinueListRequest = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.ContinueListRequest").msgclass, T.untyped)
    ContinueListDirection = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.ContinueListDirection").enummodule, T.untyped)
    SortableProperty = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.SortableProperty").enummodule, T.untyped)
    ScanRootPathsRequest = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.ScanRootPathsRequest").msgclass, T.untyped)
    ScanRootPathsResponse = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.ScanRootPathsResponse").msgclass, T.untyped)
    ScanRootPathResult = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.db.ScanRootPathResult").msgclass, T.untyped)

    module DatabaseService
      Stub = T.let(Service.rpc_stub_class, T.untyped)

      # DatabaseService is the service for creating, reading, updating and deleting data
      # in a StatelyDB Store. Creating and modifying Stores is done by
      # stately.dbmanagement.ManagementService.
      class Service
        include GRPC::GenericService
      end
    end
  end

  module Auth
    GetAuthTokenRequest = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.auth.GetAuthTokenRequest").msgclass, T.untyped)
    GetAuthTokenResponse = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.auth.GetAuthTokenResponse").msgclass, T.untyped)

    module AuthService
      Stub = T.let(Service.rpc_stub_class, T.untyped)

      # AuthService is the service for vending access tokens used to connect to
      # StatelyDB. This API is meant to be used from SDKs. Access Keys are created
      # and managed from the stately.dbmanagement.UserService.
      class Service
        include GRPC::GenericService
      end
    end
  end

  module Errors
    StatelyErrorDetails = T.let(::Google::Protobuf::DescriptorPool.generated_pool.lookup("stately.errors.StatelyErrorDetails").msgclass, T.untyped)
  end
end

module StatelyCode
  CACHED_SCHEMA_TOO_OLD = T.let("CachedSchemaTooOld", T.untyped)
  CONCURRENT_MODIFICATION = T.let("ConcurrentModification", T.untyped)
  CONDITIONAL_CHECK_FAILED = T.let("ConditionalCheckFailed", T.untyped)
  NON_RECOVERABLE_TRANSACTION = T.let("NonRecoverableTransaction", T.untyped)
  STORE_IN_USE = T.let("StoreInUse", T.untyped)
  STORE_REQUEST_LIMIT_EXCEEDED = T.let("StoreRequestLimitExceeded", T.untyped)
  STORE_THROUGHPUT_EXCEEDED = T.let("StoreThroughputExceeded", T.untyped)
end
