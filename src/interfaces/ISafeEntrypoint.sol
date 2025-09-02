// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ISafeManageable} from 'interfaces/ISafeManageable.sol';

/**
 * @title ISafeEntrypoint
 * @notice Interface for the SafeEntrypoint contract
 */
interface ISafeEntrypoint is ISafeManageable {
  // ~~~ STRUCTS ~~~

  /**
   * @notice Information about a transaction
   * @param actionsData The encoded actions data
   * @param executableAt The timestamp from which the transaction can be executed
   * @param expiresAt The timestamp from which the transaction expires
   */
  struct TransactionInfo {
    bytes actionsData;
    uint256 executableAt;
    uint256 expiresAt;
  }

  // ~~~ EVENTS ~~~

  /**
   * @notice Emitted when an actions builder is approved
   * @param _actionsBuilder The address of the actions builder contract
   * @param _approvalDuration The duration (in seconds) of the approval to the actions builder contract (0 means disapproval)
   * @param _approvalExpiresAt The timestamp from which the actions builder contract is no longer approved to be queued
   */
  event ActionsBuilderApproved(
    address indexed _actionsBuilder, uint256 indexed _approvalDuration, uint256 indexed _approvalExpiresAt
  );

  /**
   * @notice Emitted when a transaction is queued
   * @param _actionHub The actionHub contract address (0 if no actionHub was used)
   * @param _actionsBuilder The actions builder contract address
   */
  event TransactionQueued(address _actionHub, address indexed _actionsBuilder);

  /**
   * @notice Emitted when a transaction is executed
   * @param _actionsBuilder The actions builder contract address
   * @param _safeTxHash The hash of the Safe transaction
   * @param _signers The array of signer addresses
   */
  event TransactionExecuted(address indexed _actionsBuilder, bytes32 indexed _safeTxHash, address[] _signers);

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

  // ~~~ ADMIN METHODS ~~~

  /**
   * @notice Approves an actions builder to be queued
   * @dev Can only be called by the Safe contract
   * @param _actionsBuilder The address of the actions builder contract to approve
   * @param _approvalDuration The duration (in seconds) of the approval to the actions builder contract (0 means disapproval)
   */
  function approveActionsBuilder(address _actionsBuilder, uint256 _approvalDuration) external;

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
   * @param _actionsBuilder The actions builder contract address to queue
   */
  function queueTransaction(address _actionsBuilder) external;

  /**
   * @notice Executes a queued transaction using the approved hash signers
   * @dev Can be called by anyone
   * @dev The transaction must have passed its execution delay period, but not its expiry delay period
   * @param _actionsBuilder The actions builder contract address of the transaction to execute
   */
  function executeTransaction(address _actionsBuilder) external payable;

  // ~~~ STORAGE METHODS ~~~

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
   * @param _actionsBuilder The actions builder contract address
   * @return _actionsData The encoded actions data
   * @return _executableAt The timestamp from which the transaction can be executed
   * @return _expiresAt The timestamp from which the transaction expires
   */
  function queuedTransactions(address _actionsBuilder)
    external
    view
    returns (bytes memory _actionsData, uint256 _executableAt, uint256 _expiresAt);

  // ~~~ GETTER METHODS ~~~

  /**
   * @notice Gets the Safe transaction hash for an actions builder
   * @param _actionsBuilder The actions builder contract address
   * @return _safeTxHash The Safe transaction hash
   */
  function getSafeTransactionHash(address _actionsBuilder) external view returns (bytes32 _safeTxHash);

  /**
   * @notice Gets the Safe transaction hash for an actions builder with a specific Safe nonce
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
   * @param _actionsBuilder The actions builder contract address
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
