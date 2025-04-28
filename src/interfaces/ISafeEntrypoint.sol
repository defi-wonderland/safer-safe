// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ISafeManageable} from 'interfaces/ISafeManageable.sol';
import {ITransactionBuilder} from 'interfaces/actions/ITransactionBuilder.sol';

/**
 * @title ISafeEntrypoint
 * @notice Interface for the SafeEntrypoint contract
 */
interface ISafeEntrypoint is ISafeManageable {
  // ~~~ STRUCTS ~~~

  /**
   * @notice Information about a transaction builder
   * @param isApproved Whether the transaction builder contract is approved to be executed
   * @param isQueued Whether the transaction builder contract is currently queued for execution
   * @param expiryTime The timestamp after which the transaction builder contract is no longer approved (0 means no expiry)
   */
  struct TransactionBuilderInfo {
    bool isApproved;
    bool isQueued;
    uint256 expiryTime;
  }

  /**
   * @notice Information about a transaction
   * @param transactionBuilders The batch of transaction builder contract addresses associated
   * @param actionsData The encoded actions data
   * @param executableAt The timestamp after which the transaction can be executed
   * @param isExecuted Whether the transaction has been executed
   */
  struct TransactionInfo {
    address[] transactionBuilders;
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
   * @notice Gets the global nonce
   * @return _txNonce The nonce to ensure unique IDs for identical transactions
   */
  function transactionNonce() external view returns (uint256 _txNonce);

  // ~~~ EVENTS ~~~

  /**
   * @notice Emitted when a transaction builder is approved
   * @param _txBuilder The address of the transaction builder contract
   */
  event TransactionBuilderApproved(address _txBuilder);

  /**
   * @notice Emitted when a transaction builder is disapproved
   * @param _txBuilder The address of the transaction builder contract
   */
  event TransactionBuilderDisapproved(address _txBuilder);

  /**
   * @notice Emitted when a transaction is queued
   * @param _txId The ID of the transaction
   * @param _txExecutableAt The timestamp from which the transaction can be executed
   * @param _isArbitrary Whether the transaction is arbitrary or pre-approved
   */
  event TransactionQueued(uint256 _txId, uint256 _txExecutableAt, bool _isArbitrary);

  /**
   * @notice Emitted when a transaction is executed
   * @param _txId The ID of the transaction
   * @param _safeTxHash The hash of the Safe transaction
   */
  event TransactionExecuted(uint256 _txId, bytes32 _safeTxHash);

  /**
   * @notice Emitted when a transaction is unqueued
   * @param _txId The ID of the transaction
   */
  event TransactionUnqueued(uint256 _txId);

  // ~~~ ERRORS ~~~

  /**
   * @notice Thrown when a transaction builder is already approved
   */
  error TransactionBuilderAlreadyApproved();

  /**
   * @notice Thrown when a transaction builder is not approved
   */
  error TransactionBuilderNotApproved();

  /**
   * @notice Thrown when a transaction builder is already queued
   */
  error TransactionBuilderAlreadyQueued();

  /**
   * @notice Thrown when a transaction builder has expired
   */
  error TransactionBuilderExpired();

  /**
   * @notice Thrown when a transaction is not executable
   */
  error TransactionNotExecutable();

  /**
   * @notice Thrown when a transaction has already been executed
   */
  error TransactionAlreadyExecuted();

  /**
   * @notice Thrown when a transaction is not queued
   */
  error TransactionNotQueued();

  /**
   * @notice Thrown when an expiry time is invalid (not in the future)
   */
  error InvalidExpiryTime();

  /**
   * @notice Thrown when an empty transaction builders array is provided
   */
  error EmptyTransactionBuildersArray();

  /**
   * @notice Thrown when an empty actions array is provided
   */
  error EmptyActionsArray();

  /**
   * @notice Thrown when a call to a transaction builder fails
   */
  error NotSuccess();

  // ~~~ ADMIN METHODS ~~~

  /**
   * @notice Approves a transaction builder to be executed
   * @dev Can only be called by the Safe contract
   * @param _txBuilder The address of the transaction builder contract to approve
   * @param _expiryTime The timestamp after which the transaction builder contract is no longer approved (0 means no expiry)
   */
  function approveTransactionBuilder(address _txBuilder, uint256 _expiryTime) external;

  /**
   * @notice Disapproves a transaction builder from being executed
   * @dev Can only be called by the Safe owners
   * @param _txBuilder The address of the transaction builder contract to disapprove
   */
  function disapproveTransactionBuilder(address _txBuilder) external;

  // ~~~ TRANSACTION METHODS ~~~

  /**
   * @notice Queues a transaction bulked from multiple transaction builders for execution after a 1-hour delay
   * @dev Can only be called by the Safe owners
   * @dev The transaction builder contracts must be pre-approved using approveTransactionBuilder
   * @dev The transaction builder contracts must not be already in the queue
   * @param _txBuilders The batch of transaction builder contract addresses to queue
   * @return _txId The ID of the queued transaction
   */
  function queueTransaction(address[] memory _txBuilders) external returns (uint256 _txId);

  /**
   * @notice Queues an arbitrary transaction for execution after a 7-day delay
   * @dev Can only be called by the Safe owners
   * @dev The actions must be properly formatted for each target contract
   * @param _actions The batch of actions to queue
   * @return _txId The ID of the queued transaction
   */
  function queueTransaction(ITransactionBuilder.Action[] memory _actions) external returns (uint256 _txId);

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
   * @notice Gets the information about a transaction builder
   * @param _txBuilder The address of the transaction builder contract
   * @return _isApproved Whether the transaction builder contract is approved to be executed
   * @return _isQueued Whether the transaction builder contract is currently queued for execution
   * @return _expiryTime The timestamp after which the transaction builder contract is no longer approved (0 means no expiry)
   */
  function getTransactionBuilderInfo(address _txBuilder)
    external
    view
    returns (bool _isApproved, bool _isQueued, uint256 _expiryTime);

  /**
   * @notice Gets the information about a transaction
   * @param _txId The ID of the transaction
   * @return _txBuilders The batch of transaction builder contract addresses associated
   * @return _actionsData The encoded actions data
   * @return _executableAt The timestamp after which the transaction can be executed
   * @return _isExecuted Whether the transaction has been executed
   */
  function getTransactionInfo(uint256 _txId)
    external
    view
    returns (address[] memory _txBuilders, bytes memory _actionsData, uint256 _executableAt, bool _isExecuted);

  /**
   * @notice Gets the Safe transaction hash for a transaction builder
   * @param _txBuilder The address of the transaction builder contract
   * @return _safeTxHash The Safe transaction hash
   */
  function getSafeTransactionHash(address _txBuilder) external view returns (bytes32 _safeTxHash);

  /**
   * @notice Gets the Safe transaction hash for a transaction builder with a specific Safe nonce
   * @param _txBuilder The address of the transaction builder contract
   * @param _safeNonce The Safe nonce to use for the hash calculation
   * @return _safeTxHash The Safe transaction hash
   */
  function getSafeTransactionHash(address _txBuilder, uint256 _safeNonce) external view returns (bytes32 _safeTxHash);

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
