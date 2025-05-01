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
   * @notice Information about an actions builder
   * @param approvalExpiryTime The timestamp from which the actions builder contract is no longer approved to be executed
   * @param queuedTransactionId The ID of the transaction in which the actions builder contract is currently queued for execution (0 means not in queue)
   */
  struct ActionsBuilderInfo {
    uint256 approvalExpiryTime;
    uint256 queuedTransactionId;
  }

  /**
   * @notice Information about a transaction
   * @param actionsBuilders The batch of actions builder contract addresses associated
   * @param actionsData The encoded actions data
   * @param executableAt The timestamp from which the transaction can be executed
   * @param isExecuted Whether the transaction has been executed
   */
  struct TransactionInfo {
    address[] actionsBuilders;
    bytes actionsData;
    uint256 executableAt;
    bool isExecuted;
  }

  // ~~~ STORAGE METHODS ~~~

  /**
   * @notice Gets the short delay applied to pre-approved transactions
   * @return _shortDelay The short delay (in seconds)
   */
  function SHORT_DELAY() external view returns (uint256 _shortDelay);

  /**
   * @notice Gets the long delay applied to arbitrary transactions
   * @return _longDelay The long delay (in seconds)
   */
  function LONG_DELAY() external view returns (uint256 _longDelay);

  /**
   * @notice Gets the MultiSendCallOnly contract
   * @return _multiSendCallOnly The MultiSendCallOnly contract address
   */
  function MULTI_SEND_CALL_ONLY() external view returns (address _multiSendCallOnly);

  /**
   * @notice Gets the global nonce
   * @return _txNonce The nonce to ensure unique IDs for identical transactions
   */
  function transactionNonce() external view returns (uint256 _txNonce);

  // ~~~ EVENTS ~~~

  /**
   * @notice Emitted when an actions builder is approved
   * @param _actionsBuilder The address of the actions builder contract
   * @param _approvalDuration The duration (in seconds) of the approval to the actions builder contract (0 means disapproval)
   * @param _approvalExpiryTime The timestamp from which the actions builder contract is no longer approved to be executed
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
   * @notice Approves an actions builder to be executed
   * @dev Can only be called by the Safe contract
   * @param _actionsBuilder The address of the actions builder contract to approve
   * @param _approvalDuration The duration (in seconds) of the approval to the actions builder contract (0 means disapproval)
   */
  function approveActionsBuilder(address _actionsBuilder, uint256 _approvalDuration) external;

  // ~~~ TRANSACTION METHODS ~~~

  /**
   * @notice Queues a transaction bulked from multiple actions builders for execution after a 1-hour delay
   * @dev Can only be called by the Safe owners
   * @dev The actions builder contracts must be pre-approved using approveActionsBuilder
   * @dev The actions builder contracts must not be already in the queue
   * @param _actionsBuilders The batch of actions builder contract addresses to queue
   * @return _txId The ID of the queued transaction
   */
  function queueTransaction(address[] memory _actionsBuilders) external returns (uint256 _txId);

  /**
   * @notice Queues an arbitrary transaction for execution after a 7-day delay
   * @dev Can only be called by the Safe owners
   * @dev The actions must be properly formatted for each target contract
   * @param _actions The batch of actions to queue
   * @return _txId The ID of the queued transaction
   */
  function queueTransaction(IActionsBuilder.Action[] memory _actions) external returns (uint256 _txId);

  /**
   * @notice Executes a queued transaction using the approved signers
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
  function executeTransaction(uint256 _txId, address[] memory _signers) external payable;

  /**
   * @notice Unqueues a pending transaction before it is executed
   * @dev Can only be called by the Safe owners
   * @param _txId The ID of the transaction to unqueue
   */
  function unqueueTransaction(uint256 _txId) external;

  // ~~~ VIEW METHODS ~~~

  /**
   * @notice Gets the information about an actions builder
   * @param _actionsBuilder The address of the actions builder contract
   * @return _approvalExpiryTime The timestamp from which the actions builder contract is no longer approved to be executed
   * @return _queuedTransactionId The ID of the transaction in which the actions builder contract is currently queued for execution (0 means not in queue)
   */
  function getActionsBuilderInfo(address _actionsBuilder)
    external
    view
    returns (uint256 _approvalExpiryTime, uint256 _queuedTransactionId);

  /**
   * @notice Gets the information about a transaction
   * @param _txId The ID of the transaction
   * @return _actionsBuilders The batch of actions builder contract addresses associated
   * @return _actionsData The encoded actions data
   * @return _executableAt The timestamp from which the transaction can be executed
   * @return _isExecuted Whether the transaction has been executed
   */
  function getTransactionInfo(uint256 _txId)
    external
    view
    returns (address[] memory _actionsBuilders, bytes memory _actionsData, uint256 _executableAt, bool _isExecuted);

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
   * @notice Gets the list of signers who have approved a transaction
   * @param _txId The ID of the transaction
   * @return _approvedHashSigners The array of approved hash signer addresses
   */
  function getApprovedHashSigners(uint256 _txId) external view returns (address[] memory _approvedHashSigners);
}
