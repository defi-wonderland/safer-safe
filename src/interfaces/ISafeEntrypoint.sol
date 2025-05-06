// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ISafeManageable} from 'interfaces/ISafeManageable.sol';
import {IActionsBuilder} from 'interfaces/actions/IActionsBuilder.sol';

/**
 * @title ISafeEntrypoint
 * @notice Interface for the SafeEntrypoint contract
 */
interface ISafeEntrypoint is ISafeManageable {
  // ~~~ STRUCTS ~~~

  /**
   * @notice Information about a transaction
   * @param actionsBuilder The actions builder contract address associated
   * @param actionsData The encoded actions data
   * @param executableAt The timestamp from which the transaction can be executed
   * @param isExecuted Whether the transaction has been executed
   */
  struct TransactionInfo {
    address actionsBuilder;
    bytes actionsData;
    uint256 executableAt;
    bool isExecuted;
  }

  // ~~~ STORAGE METHODS ~~~

  /**
   * @notice Gets the MultiSendCallOnly contract
   * @return _multiSendCallOnly The MultiSendCallOnly contract address
   */
  function MULTI_SEND_CALL_ONLY() external view returns (address _multiSendCallOnly);

  /**
   * @notice Gets the short execution delay applied to pre-approved transactions
   * @return _shortExecutionDelay The short execution delay (in seconds)
   */
  function SHORT_EXECUTION_DELAY() external view returns (uint256 _shortExecutionDelay);

  /**
   * @notice Gets the long execution delay applied to arbitrary transactions
   * @return _longExecutionDelay The long execution delay (in seconds)
   */
  function LONG_EXECUTION_DELAY() external view returns (uint256 _longExecutionDelay);

  /**
   * @notice Gets the global nonce
   * @return _txNonce The nonce to ensure unique IDs for identical transactions
   */
  function transactionNonce() external view returns (uint256 _txNonce);

  /**
   * @notice Gets the expiry time for an actions builder
   * @param _actionsBuilder The address of the actions builder contract
   * @return _expiryTime The timestamp from which the actions builder contract is no longer approved to be queued
   */
  function actionsBuilderExpiryTime(address _actionsBuilder) external view returns (uint256 _expiryTime);

  // ~~~ EVENTS ~~~

  /**
   * @notice Emitted when an actions builder is approved
   * @param _actionsBuilder The address of the actions builder contract
   * @param _approvalDuration The duration (in seconds) of the approval to the actions builder contract (0 means disapproval)
   * @param _approvalExpiryTime The timestamp from which the actions builder contract is no longer approved to be queued
   */
  event ActionsBuilderApproved(
    address indexed _actionsBuilder, uint256 indexed _approvalDuration, uint256 indexed _approvalExpiryTime
  );

  /**
   * @notice Emitted when a transaction is queued
   * @param _txId The ID of the transaction
   * @param _isArbitrary Whether the transaction is arbitrary or pre-approved
   */
  event TransactionQueued(uint256 indexed _txId, bool indexed _isArbitrary);

  /**
   * @notice Emitted when a transaction is executed
   * @param _txId The ID of the transaction
   * @param _isArbitrary Whether the transaction is arbitrary or pre-approved
   * @param _safeTxHash The hash of the Safe transaction
   * @param _signers The array of signer addresses
   */
  event TransactionExecuted(
    uint256 indexed _txId, bool indexed _isArbitrary, bytes32 indexed _safeTxHash, address[] _signers
  );

  /**
   * @notice Emitted when a transaction is unqueued
   * @param _txId The ID of the transaction
   * @param _isArbitrary Whether the transaction is arbitrary or pre-approved
   */
  event TransactionUnqueued(uint256 indexed _txId, bool indexed _isArbitrary);

  // ~~~ ERRORS ~~~

  /**
   * @notice Thrown when an actions builder is not approved
   */
  error ActionsBuilderNotApproved();

  /**
   * @notice Thrown when an actions builder is already queued
   */
  error ActionsBuilderAlreadyQueued();

  /**
   * @notice Thrown when a transaction is not yet executable
   */
  error TransactionNotYetExecutable();

  /**
   * @notice Thrown when a transaction has already been executed
   */
  error TransactionAlreadyExecuted();

  /**
   * @notice Thrown when a transaction is not queued
   */
  error TransactionNotQueued();

  /**
   * @notice Thrown when an empty actions builders array is provided
   */
  error EmptyActionsBuildersArray();

  /**
   * @notice Thrown when an empty actions array is provided
   */
  error EmptyActionsArray();

  /**
   * @notice Thrown when a call to an actions builder fails
   */
  error NotSuccess();

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
   * @notice Queues a transaction from an actions builder for execution after a 1-hour delay
   * @dev Can only be called by the Safe owners
   * @dev The actions builder contract must be pre-approved using approveActionsBuilder
   * @param _actionsBuilder The actions builder contract address to queue
   * @return _txId The ID of the queued transaction
   */
  function queueTransaction(address _actionsBuilder) external returns (uint256 _txId);

  /**
   * @notice Queues an arbitrary transaction for execution after a 7-day delay
   * @dev Can only be called by the Safe owners
   * @param _action The action to queue
   * @return _txId The ID of the queued transaction
   */
  function queueTransaction(IActionsBuilder.Action calldata _action) external returns (uint256 _txId);

  /**
   * @notice Executes a queued transaction using the approved hash signers
   * @dev Can be called by anyone
   * @dev The transaction must have passed its delay period
   * @param _txId The ID of the transaction to execute
   */
  function executeTransaction(uint256 _txId) external payable;

  /**
   * @notice Executes a queued transaction using the specified signers
   * @dev Can be called by anyone
   * @dev The transaction must have passed its delay period
   * @param _txId The ID of the transaction to execute
   * @param _signers The array of signer addresses
   */
  function executeTransaction(uint256 _txId, address[] calldata _signers) external payable;

  /**
   * @notice Unqueues a pending transaction before it is executed
   * @dev Can only be called by the Safe owners
   * @param _txId The ID of the transaction to unqueue
   */
  function unqueueTransaction(uint256 _txId) external;

  // ~~~ VIEW METHODS ~~~

  /**
   * @notice Gets the information about a transaction
   * @param _txId The ID of the transaction
   * @return _actionsBuilder The actions builder contract address associated
   * @return _actionsData The encoded actions data
   * @return _executableAt The timestamp from which the transaction can be executed
   * @return _isExecuted Whether the transaction has been executed
   */
  function getTransactionInfo(uint256 _txId)
    external
    view
    returns (address _actionsBuilder, bytes memory _actionsData, uint256 _executableAt, bool _isExecuted);

  /**
   * @notice Gets the Safe transaction hash for a transaction ID
   * @param _txId The ID of the transaction
   * @return _safeTxHash The Safe transaction hash
   */
  function getSafeTransactionHash(uint256 _txId) external view returns (bytes32 _safeTxHash);

  /**
   * @notice Gets the Safe transaction hash for a transaction ID with a specific Safe nonce
   * @param _txId The ID of the transaction
   * @param _safeNonce The Safe nonce to use for the hash calculation
   * @return _safeTxHash The Safe transaction hash
   */
  function getSafeTransactionHash(uint256 _txId, uint256 _safeNonce) external view returns (bytes32 _safeTxHash);

  /**
   * @notice Gets the list of signers who have approved a Safe transaction hash for a transaction ID
   * @param _txId The ID of the transaction
   * @return _approvedHashSigners The array of approved hash signer addresses
   */
  function getApprovedHashSigners(uint256 _txId) external view returns (address[] memory _approvedHashSigners);

  /**
   * @notice Gets the list of signers who have approved a Safe transaction hash for a transaction ID with a specific Safe nonce
   * @param _txId The ID of the transaction
   * @param _safeNonce The Safe nonce to use for the hash calculation
   * @return _approvedHashSigners The array of approved hash signer addresses
   */
  function getApprovedHashSigners(
    uint256 _txId,
    uint256 _safeNonce
  ) external view returns (address[] memory _approvedHashSigners);

  /**
   * @notice Gets the list of signers who have approved a Safe transaction hash for a Safe transaction hash
   * @param _safeTxHash The hash of the Safe transaction
   * @return _approvedHashSigners The array of approved hash signer addresses
   */
  function getApprovedHashSigners(bytes32 _safeTxHash) external view returns (address[] memory _approvedHashSigners);
}
