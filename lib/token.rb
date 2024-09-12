# frozen_string_literal: true

module StatelyDB
  # The Token type contains a continuation token for list and sync operations along with metadata about the ability
  # to sync or continue listing based on the last operation performed.
  #
  # Ths StatelyDB SDK vends this Token type for list and sync operations. Consumers should not need to construct this
  # type directly.
  class Token
    # @!visibility private
    attr_accessor :token_data

    # @param [String] token_data
    # @param [Boolean] can_continue
    # @param [Boolean] can_sync
    def initialize(token_data:, can_continue:, can_sync:)
      @token_data = token_data
      @can_continue = can_continue
      @can_sync = can_sync
    end

    # Returns true if the list operation can be continued, otherwise false.
    # @return [Boolean]
    def can_continue?
      !!@can_continue
    end

    # Returns true if the sync operation can be continued, otherwise false.
    # @return [Boolean]
    def can_sync?
      !!@can_sync
    end
  end
end
