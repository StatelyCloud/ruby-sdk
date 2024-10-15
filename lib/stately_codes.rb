# frozen_string_literal: true

module StatelyCode
  # ConcurrentModification indicates the current transaction was aborted
  # because of a non-serializable interaction with another transaction was
  # detected, a stale read was detected, or because attempts to resolve an
  # otherwise serializable interaction have exceeded the maximum number of
  # internal resolution retries. Examples:
  #
  # 1. TransactionA and TransactionB are opened concurrently. TransactionA
  # reads ItemX, puts ItemY. Before transactionA can commit, transactionB
  # writes ItemX and commits. When transactionA tries to commit, it will fail
  # with ConcurrentModification because the read of ItemX in transactionA is
  # no longer valid. That is, the data in ItemX which leads to the decision to
  # put ItemY may have changed, and thus a conflict is detected.
  #
  # 2. TransactionA is opened which writes ItemA with an initialValue field (a
  # field used for ID assignment) -- the generated ID is returned to the
  # client. transactionB also performs a on an item which resolves to the same
  # initialValue, transactionB is committed first. Since transactionA may have
  # acted on the generatedID (e.g. written in a different record), it will be
  # aborted because the ID is no longer valid for the item it was intended
  # for.
  #
  # 3. A read or list operation detected that underlying data has changed
  # since the transaction began.
  #
  # - Retryable
  #     This error is immediately retryable.
  CONCURRENT_MODIFICATION = "ConcurrentModification"

  # ConditionalCheckFailed indicates that conditions provided to perform an
  # operation were not met. For example, a condition to write an item only if
  # it does not already exist. In the future StatelyDB may provide more
  # information about the failed condition; if this feature is a blocker,
  # please contact support.
  #
  # - Not Retryable
  #     Typically a conditional check failure is not retryable
  #     unless the conditions for the operation are changed.
  CONDITIONAL_CHECK_FAILED = "ConditionalCheckFailed"

  # NonRecoverableTransaction indicates that conditions required for the
  # transaction to succeed are not possible to meet with the current state of
  # the system. This can occur when an Item has more than one key-path, and is
  # written with a "must not exist" condition (e.g. with ID Generation on one
  # of the keys) but another keys already maps to an existing item in the
  # store. Permitting such a write would result in conflicting state; two
  # independent records with aliases pointing to the same item.
  #
  # - Not Retryable
  NON_RECOVERABLE_TRANSACTION = "NonRecoverableTransaction"

  # StoreInUse indicates that the underlying Store is currently in being
  # updated and cannot be modified until the operation in progress has
  # completed.
  #
  # - Retryable
  #     This can be retried with backoff.
  STORE_IN_USE = "StoreInUse"

  # StoreRequestLimitExceeded indicates that an attempt to modify a Store has
  # been temporarily rejected due to exceeding global modification limits.
  # StatelyDB has been notified about this error and will take necessary
  # actions to correct it. In the event that the issue has not been resolved,
  # please contact support.
  #
  # - Retryable
  STORE_REQUEST_LIMIT_EXCEEDED = "StoreRequestLimitExceeded"

  # StoreThroughputExceeded indicates that the underlying Store does not have
  # resources to complete the request. This may indicate a request rate is too
  # high to a specific Group or that a sudden burst of traffic has exceeded a
  # Store's provisioned capacity.
  #
  # - Retryable
  #     With an exponential backoff.
  STORE_THROUGHPUT_EXCEEDED = "StoreThroughputExceeded"
end
