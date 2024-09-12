# frozen_string_literal: true

module StatelyDB
  module Transaction
    # TransactionQueue is a wrapper around Thread::Queue that implements Enumerable
    class Queue < Thread::Queue
      # @!attribute [r] last_message_id
      # @return [Integer, nil] The ID of the last message, or nil if there is no message.
      attr_reader :last_message_id

      def initialize
        super
        @last_message_id = 0
      end

      # next_message_id returns the next message ID, which is the current size of the queue + 1.
      # This value is consumed by the StatelyDB transaction as a monotonically increasing MessageID.
      # @return [Integer]
      def next_message_id
        @last_message_id += 1
      end

      # Iterates over each element in the queue, yielding each element to the given block.
      #
      # @yield [Object] Gives each element in the queue to the block.
      # @return [void]
      def each
        loop do
          yield pop
        end
      end

      # Iterates over each item in the queue, yielding each item to the given block.
      #
      # @yield [Object] Gives each item in the queue to the block.
      # @return [void]
      def each_item
        loop do
          yield pop
        end
      end
    end
  end
end
