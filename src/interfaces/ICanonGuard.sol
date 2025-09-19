// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ISafeManageable} from 'interfaces/ISafeManageable.sol';

/**
 * @title ICanonGuard
 * @notice Interface for the CanonGuard contract
 */
interface ICanonGuard is ISafeManageable {
  // ~~~ STRUCTS ~~~

  /**
   * @notice Information about a transaction
   * @param proposer The address of the proposer of the transaction
   * @param actionsData The encoded actions data
   * @param executableAt The timestamp from which the transaction can be executed
   * @param expiresAt The timestamp from which the transaction expires
   */
  struct TransactionInfo {
    address proposer;
    bytes actionsData;
    uint256 executableAt;
    uint256 expiresAt;
  }

  // ~~~ EVENTS ~~~

  /**
   * @notice Emitted when an actions builder is approved
   * @param _actionsBuilderOrHub The address of the actions builder or hub contract
   * @param _approvalDuration The duration (in seconds) of the approval to the actions builder or hub contract (0 means disapproval)
   * @param _approvalExpiresAt The timestamp from which the actions builder or hub contract is no longer approved to be queued
   */
  event ActionsBuilderOrHubApproved(
    address indexed _actionsBuilderOrHub, uint256 indexed _approvalDuration, uint256 indexed _approvalExpiresAt
  );

  /**
   * @notice Emitted when a transaction is queued
   * @param _actionHub The actionHub contract address (0 if no actionHub was used)
   * @param _proposer The address of the proposer of the transaction
   * @param _actionsBuilder The actions builder contract address
   * @param _txIsPreApproved Whether the transaction is pre-approved
   */
  event TransactionQueued(
    address indexed _actionHub, address indexed _proposer, address indexed _actionsBuilder, bool _txIsPreApproved
  );

  /**
   * @notice Emitted when a transaction is executed
   * @param _actionsBuilder The actions builder contract address
   * @param _safeTxHash The hash of the Safe transaction
   * @param _signers The array of sorted signer addresses.
   */
  event TransactionExecuted(address indexed _actionsBuilder, bytes32 indexed _safeTxHash, address[] _signers);

  /**
   * @notice Emitted when an empty transaction is executed
   * @param _safeTxHash The hash of the Safe transaction
   * @param _signers The array of signer addresses
   */
  event NoActionTransactionExecuted(bytes32 indexed _safeTxHash, address[] _signers);

  /**
   * @notice Emitted when a enqueued transaction is cancelled
   * @param _actionsBuilder The actions builder contract address
   * @param _proposer The address of the proposer of the transaction
   * @param _safeTxHash The hash of the Safe transaction
   */
  event EnqueuedTransactionCancelled(
    address indexed _actionsBuilder, address indexed _proposer, bytes32 indexed _safeTxHash
  );

  /**
   * @notice Thrown when no transaction is queued for the actions builder
   */
  error NoTransactionQueued();

  /**
   * @notice Thrown when a transaction is not yet executable
   */
  error TransactionNotYetExecutable();

  /**
   * @notice Thrown when a transaction has expired
   */
  error TransactionExpired();

  /**
   * @notice Thrown when attempting to queue a transaction that has already been queued
   * @param _actionsBuilder The address of the actions builder contract
   */
  error TransactionAlreadyQueued(address _actionsBuilder);

  /**
   * @notice Thrown when an invalid actionHub or actions builder is provided
   */
  error InvalidHubOrActionsBuilder();

  /**
   * @notice Thrown when an invalid approval duration is provided
   */
  error InvalidApprovalDuration();

  /**
   * @notice Thrown when the transaction expiry delay is less than the minimum expiry time
   */
  error TxExpiryDelayCannotBeLessThanMin();

  /**
   * @notice Thrown when the maximum approval duration is less than the minimum expiry time
   */
  error MaxApprovalDurationCannotBeLessThanMin();

  /**
   * @notice Thrown when the delay configuration is invalid
   */
  error InvalidDelayConfiguration();

  /**
   * @notice Thrown when the short transaction execution delay is greater than the long transaction execution delay
   */
  error ShortDelayCannotBeGreaterThanLongDelay();

  /**
   * @notice Thrown when the transaction expiry delay is greater than the maximum value (uint128.max)
   */
  error TxExpiryDelayCannotBeGreaterThanMax();

  /**
   * @notice Thrown when the long transaction execution delay is greater than the maximum value (uint128.max)
   */
  error LongDelayCannotBeGreaterThanMax();

  /**
   * @notice Thrown when queueing a transaction that is not an ActionsBuilder
   */
  error NotAnActionsBuilder();

  /**
   * @notice Thrown when the caller is not the proposer of the transaction being cancelled
   */
  error CallerMustBeTransactionProposer();

  /**
   * @notice Thrown when attempting to cancel a transaction with approved hash signers
   */
  error TransactionWithSignaturesCannotBeCancelled();

  // ~~~ ADMIN METHODS ~~~

  /**
   * @notice Approves an actions builder to be queued
   * @dev Can only be called by the Safe contract
   * @param _actionsBuilder The address of the actions builder contract to approve
   * @param _approvalDuration The duration (in seconds) of the approval to the actions builder contract (0 means disapproval)
   */
  function approveActionsBuilderOrHub(address _actionsBuilder, uint256 _approvalDuration) external;

  // ~~~ TRANSACTION METHODS ~~~

  /**
   * @notice Verifies if the actions builder is a child of the actionHub, queues a transaction from an actions builder, for execution after a short delay if approved, or after a long delay if not approved
   * @dev Can only be called by the Safe owners
   * @param _actionHub The actionHub contract address
   * @param _actionsBuilder The actions builder contract address to queue
   */
  function queueHubTransaction(address _actionHub, address _actionsBuilder) external;

  /**
   * @notice Queues a transaction from an actions builder for execution after a short delay if approved, or after a long delay if not approved
   * @dev Can only be called by the Safe owners
   * @param _actionsBuilder The actions builder contract address to queue. Reverts if it is not an ActionsBuilder.
   */
  function queueTransaction(address _actionsBuilder) external;

  /**
   * @notice Executes a queued transaction using the approved hash signers
   * @dev Can be called by anyone
   * @dev The transaction must have passed its execution delay period, but not its expiry delay period
   * @param _actionsBuilder The actions builder contract address of the transaction to execute
   */
  function executeTransaction(address _actionsBuilder) external payable;

  /**
   * @notice Executes an empty transaction, in order to use the safe nonce.
   * @notice This will nullify the signatures for that specific safe nonce.
   * @dev Can be called by anyone if not in emergency mode
   */
  function executeNoActionTransaction() external;

  /**
   * @notice Cancels an enqueued transaction
   * @notice Can only be called by the proposer of the transaction
   * @notice The transaction must not have any approved hash signers
   * @param _actionsBuilder The actions builder contract address
   */
  function cancelEnqueuedTransaction(address _actionsBuilder) external;

  // ~~~ STORAGE METHODS ~~~

  /**
   * @notice Gets the parent address
   * @return _parent The parent address. Returns address(0) if it was not deployed by a factory
   */
  function PARENT() external view returns (address _parent);

  /**
   * @notice Gets the minimum expiry time
   * @return _minExpiryTime The minimum expiry time (in seconds)
   */
  function MIN_EXPIRY_TIME() external view returns (uint256 _minExpiryTime);

  /**
   * @notice Gets the MultiSendCallOnly contract
   * @return _multiSendCallOnly The MultiSendCallOnly contract address
   */
  function MULTI_SEND_CALL_ONLY() external view returns (address _multiSendCallOnly);

  /**
   * @notice Gets the short execution delay applied to pre-approved transactions
   * @return _shortTxExecutionDelay The short transaction execution delay (in seconds)
   */
  function SHORT_TX_EXECUTION_DELAY() external view returns (uint256 _shortTxExecutionDelay);

  /**
   * @notice Gets the long execution delay applied to not approved transactions
   * @return _longTxExecutionDelay The long transaction execution delay (in seconds)
   */
  function LONG_TX_EXECUTION_DELAY() external view returns (uint256 _longTxExecutionDelay);

  /**
   * @notice Gets the default expiry delay for transactions
   * @return _txExpiryDelay The default transaction expiry delay (in seconds)
   */
  function TX_EXPIRY_DELAY() external view returns (uint256 _txExpiryDelay);

  /**
   * @notice Gets the maximum approval duration
   * @return _maxApprovalDuration The maximum approval duration for an actions builder or hub (in seconds)
   */
  function MAX_APPROVAL_DURATION() external view returns (uint256 _maxApprovalDuration);

  /**
   * @notice Gets the approval expiry time for an actions builder
   * @param _actionsBuilder The address of the actions builder contract
   * @return _approvalExpiresAt The timestamp from which the actions builder contract is no longer approved to be queued
   */
  function approvalExpiries(address _actionsBuilder) external view returns (uint256 _approvalExpiresAt);

  /**
   * @notice Gets the transaction info for an actions builder
   * @return _proposer The address of the proposer of the transaction
   * @param _actionsBuilder The actions builder contract address
   * @return _actionsData The encoded actions data
   * @return _executableAt The timestamp from which the transaction can be executed
   * @return _expiresAt The timestamp from which the transaction expires
   */
  function queuedTransactions(address _actionsBuilder)
    external
    view
    returns (address _proposer, bytes memory _actionsData, uint256 _executableAt, uint256 _expiresAt);

  // ~~~ GETTER METHODS ~~~

  /**
   * @notice Gets the Safe transaction hash for an actions builder. If the actions builder is the zero address, it will return the hash of an empty transaction.
   * @param _actionsBuilder The actions builder contract address
   * @return _safeTxHash The Safe transaction hash
   */
  function getSafeTransactionHash(address _actionsBuilder) external view returns (bytes32 _safeTxHash);

  /**
   * @notice Gets the Safe transaction hash for an actions builder with a specific Safe nonce. If the actions builder is the zero address, it will return the hash of an empty transaction.
   * @param _actionsBuilder The actions builder contract address
   * @param _safeNonce The Safe nonce to use for the hash calculation
   * @return _safeTxHash The Safe transaction hash
   */
  function getSafeTransactionHash(
    address _actionsBuilder,
    uint256 _safeNonce
  ) external view returns (bytes32 _safeTxHash);

  /**
   * @notice Gets the list of signers who have approved a Safe transaction hash for an actions builder with a specific Safe nonce
   * @param _actionsBuilder The actions builder contract address. Or the zero address if you want to execute an empty transaction
   * @param _safeNonce The Safe nonce to use for the hash calculation
   * @return _approvedHashSigners The array of approved hash signer addresses
   */
  function getApprovedHashSigners(
    address _actionsBuilder,
    uint256 _safeNonce
  ) external view returns (address[] memory _approvedHashSigners);

  /**
   * @notice Gets the Safe nonce
   * @return _safeNonce The Safe nonce
   */
  function getSafeNonce() external view returns (uint256 _safeNonce);
}
