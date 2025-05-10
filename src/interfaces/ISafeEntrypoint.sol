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
   * @param expiresAt The timestamp from which the transaction expires
   * @param isExecuted Whether the transaction has been executed
   */
  struct TransactionInfo {
    address actionsBuilder;
    bytes actionsData;
    uint256 executableAt;
    uint256 expiresAt;
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
   * @notice Gets the default expiration time for transactions
   * @return _defaultTxExpiryDelay The default expiry delay (in seconds)
   */
  function DEFAULT_TX_EXPIRY_DELAY() external view returns (uint256 _defaultTxExpiryDelay);

  /**
   * @notice Gets the global nonce
   * @return _txNonce The nonce to ensure unique IDs for identical transactions
   */
  function transactionNonce() external view returns (uint256 _txNonce);

  /**
   * @notice Gets the approval expiry time for an actions builder
   * @param _actionsBuilder The address of the actions builder contract
   * @return _expiryTime The timestamp from which the actions builder contract is no longer approved to be queued
   */
  function approvalExpiries(address _actionsBuilder) external view returns (uint256 _expiryTime);

  /**
   * @notice Gets the transaction info for a transaction ID
   * @param _txId The ID of the transaction
   * @return _actionsBuilder The actions builder contract address associated
   * @return _actionsData The encoded actions data
   * @return _executableAt The timestamp from which the transaction can be executed
   * @return _expiresAt The timestamp from which the transaction expires
   * @return _isExecuted Whether the transaction has been executed
   */
  function transactions(uint256 _txId)
    external
    view
    returns (
      address _actionsBuilder,
      bytes memory _actionsData,
      uint256 _executableAt,
      uint256 _expiresAt,
      bool _isExecuted
    );

  /**
   * @notice Gets a signer's disapproved Safe transaction hashes
   * @param _signer The address of the signer
   * @param _safeTxHash The hash of the Safe transaction
   * @return _isDisapproved Whether the Safe transaction hash has been disapproved by the signer
   */
  function disapprovedHashes(address _signer, bytes32 _safeTxHash) external view returns (bool _isDisapproved);

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
   * @notice Emitted when a Safe transaction hash is disapproved
   * @param _safeTxHash The hash of the Safe transaction that was disapproved
   * @param _signer The address of the signer who disapproved the hash
   */
  event SafeTransactionHashDisapproved(bytes32 indexed _safeTxHash, address indexed _signer);

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
   * @notice Thrown when attempting to disapprove a Safe transaction hash that hasn't been approved
   */
  error SafeTransactionHashNotApproved();

  /**
   * @notice Thrown when a call to an actions builder fails
   */
  error NotSuccess();

  /**
   * @notice Thrown when a transaction has expired
   */
  error TransactionExpired();

  /**
   * @notice Thrown when a signer is invalid
   * @param _safeTxHash The hash of the Safe transaction
   * @param _signer The address of the signer
   */
  error InvalidSigner(bytes32 _safeTxHash, address _signer);

  /**
   * @notice Thrown when attempting to disapprove a transaction hash that hasn't been approved
   */
  error TxHashNotApproved();

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
   * @param _expiryDelay The duration (in seconds) after which the transaction expires (after execution delay)
   * @return _txId The ID of the queued transaction
   */
  function queueTransaction(address _actionsBuilder, uint256 _expiryDelay) external returns (uint256 _txId);

  /**
   * @notice Queues an arbitrary transaction for execution after a long delay
   * @dev Can only be called by the Safe owners
   * @param _action The action to queue
   * @param _expiryDelay The duration (in seconds) after which the transaction expires (after execution delay)
   * @return _txId The ID of the queued transaction
   */
  function queueTransaction(
    IActionsBuilder.Action calldata _action,
    uint256 _expiryDelay
  ) external returns (uint256 _txId);

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
   * @notice Disapproves a Safe transaction hash
   * @dev Can be called by any Safe owner
   * @param _safeTxHash The hash of the Safe transaction to disapprove
   */
  function disapproveSafeTransactionHash(bytes32 _safeTxHash) external;

  // ~~~ VIEW METHODS ~~~

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
