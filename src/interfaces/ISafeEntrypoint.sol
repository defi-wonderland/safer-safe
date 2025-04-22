// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.29;

import {ISafeManageable} from 'interfaces/ISafeManageable.sol';
import {IActions} from 'interfaces/actions/IActions.sol';

/**
 * @title ISafeEntrypoint
 * @notice Interface for the SafeEntrypoint contract
 */
interface ISafeEntrypoint is ISafeManageable {
  // ~~~ STORAGE METHODS ~~~

  /**
   * @notice Gets the MultiSendCallOnly contract
   * @return _multiSendCallOnly The MultiSendCallOnly contract address
   */
  function MULTI_SEND_CALL_ONLY() external view returns (address _multiSendCallOnly);

  /**
   * @notice Maps an action contract to its approval status
   * @param _actionContract The address of the action contract
   * @return _isAllowed The approval status of the action contract
   */
  function allowedActions(address _actionContract) external view returns (bool _isAllowed);

  /**
   * @notice Maps a transaction hash to its executable timestamp
   * @param _txHash The hash of the transaction
   * @return _txExecutableAt The timestamp from which the transaction can be executed
   */
  function txExecutableAt(bytes32 _txHash) external view returns (uint256 _txExecutableAt);

  /**
   * @notice Maps a transaction hash to its data
   * @param _txHash The hash of the transaction
   * @return _txData The data of the transaction
   */
  function txData(bytes32 _txHash) external view returns (bytes memory _txData);

  /**
   * @notice Maps a transaction hash to its execution status
   * @param _txHash The hash of the transaction
   * @return _isExecuted The execution status of the action
   */
  function executedTxs(bytes32 _txHash) external view returns (bool _isExecuted);

  // ~~~ EVENTS ~~~

  /**
   * @notice Emitted when an action contract is allowed
   * @param _actionContract The address of the action contract
   */
  event ActionAllowed(address _actionContract);

  /**
   * @notice Emitted when an action contract is disallowed
   * @param _actionContract The address of the action contract
   */
  event ActionDisallowed(address _actionContract);

  /**
   * @notice Emitted when a transaction is queued
   * @param _txHash The hash of the transaction
   * @param _txExecutableAt The timestamp from which the transaction can be executed
   * @param _isArbitrary Whether the transaction is arbitrary or pre-approved
   */
  event TransactionQueued(bytes32 _txHash, uint256 _txExecutableAt, bool _isArbitrary);

  /**
   * @notice Emitted when a transaction is executed
   * @param _txHash The hash of the transaction
   * @param _safeTxHash The hash of the Safe transaction
   */
  event TransactionExecuted(bytes32 _txHash, bytes32 _safeTxHash);

  /**
   * @notice Emitted when a transaction is unqueued
   * @param _txHash The hash of the transaction
   */
  event TransactionUnqueued(bytes32 _txHash);

  // ~~~ ERRORS ~~~

  /**
   * @notice Thrown when an action contract is already allowed
   */
  error AlreadyAllowed();

  /**
   * @notice Thrown when an action contract is not allowed
   */
  error NotAllowed();

  /**
   * @notice Thrown when an empty actions array is provided
   */
  error EmptyActionsArray();

  /**
   * @notice Thrown when a transaction is not queued
   */
  error TransactionNotQueued();

  /**
   * @notice Thrown when a transaction has already been executed
   */
  error TransactionAlreadyExecuted();

  /**
   * @notice Thrown when a transaction is not executable
   */
  error TransactionNotExecutable();

  /**
   * @notice Thrown when a call to an action contract fails
   */
  error NotSuccess();

  // ~~~ ADMIN METHODS ~~~

  /**
   * @notice Allows an action contract to be executed by the Safe
   * @dev Can only be called by the Safe contract
   * @param _actionContract The address of the action contract to allow
   */
  function allowAction(address _actionContract) external;

  /**
   * @notice Disallows an action contract from being executed by the Safe
   * @dev Can only be called by the Safe owners
   * @param _actionContract The address of the action contract to disallow
   */
  function disallowAction(address _actionContract) external;

  // ~~~ ACTIONS METHODS ~~~

  /**
   * @notice Queues an approved transaction for execution after a 1-hour delay
   * @dev Can only be called by the Safe owners
   * @dev The action contract must be pre-approved using allowAction
   * @param _actionContract The address of the approved action contract
   * @return _txHash The hash of the transaction
   */
  function queueTransaction(address _actionContract) external returns (bytes32 _txHash);

  /**
   * @notice Queues an arbitrary transaction for execution after a 7-day delay
   * @dev Can only be called by the Safe owners
   * @dev The actions must be properly formatted for each target contract
   * @param _actions The array of actions to queue
   * @return _txHash The hash of the transaction
   */
  function queueTransaction(IActions.Action[] memory _actions) external returns (bytes32 _txHash);

  /**
   * @notice Executes a queued transaction using the approved signers
   * @dev The transaction must have passed its delay period
   * @param _txHash The hash of the transaction to execute
   */
  function executeTransaction(bytes32 _txHash) external payable;

  /**
   * @notice Executes a queued transaction using the provided signers
   * @dev The transaction must have passed its delay period
   * @param _txHash The hash of the transaction to execute
   * @param _signers The addresses of the signers to use
   */
  function executeTransaction(bytes32 _txHash, address[] memory _signers) external payable;

  /**
   * @notice Unqueues a pending transaction before it is executed
   * @dev Can only be called by the Safe owners
   * @param _txHash The hash of the transaction to unqueue
   */
  function unqueueTransaction(bytes32 _txHash) external;

  // ~~~ VIEW METHODS ~~~

  /**
   * @notice Gets the hash of a transaction from an action contract
   * @param _actionContract The address of the action contract
   * @param _txNonce The nonce of the transaction
   * @return _txHash The hash of the transaction
   */
  function getTransactionHash(address _actionContract, uint256 _txNonce) external view returns (bytes32 _txHash);

  /**
   * @notice Gets the Safe transaction hash for an action contract
   * @param _actionContract The address of the action contract
   * @return _safeTxHash The Safe transaction hash
   */
  function getSafeTransactionHash(address _actionContract) external view returns (bytes32 _safeTxHash);

  /**
   * @notice Gets the Safe transaction hash for an action contract with a specific nonce
   * @param _actionContract The address of the action contract
   * @param _safeNonce The nonce to use for the hash calculation
   * @return _safeTxHash The Safe transaction hash
   */
  function getSafeTransactionHash(
    address _actionContract,
    uint256 _safeNonce
  ) external view returns (bytes32 _safeTxHash);

  /**
   * @notice Gets the Safe transaction hash for an action hash
   * @param _txHash The hash of the transaction
   * @return _safeTxHash The Safe transaction hash
   */
  function getSafeTransactionHash(bytes32 _txHash) external view returns (bytes32 _safeTxHash);

  /**
   * @notice Gets the Safe transaction hash for an action hash with a specific nonce
   * @param _txHash The hash of the transaction
   * @param _safeNonce The nonce to use for the hash calculation
   * @return _safeTxHash The Safe transaction hash
   */
  function getSafeTransactionHash(bytes32 _txHash, uint256 _safeNonce) external view returns (bytes32 _safeTxHash);

  /**
   * @notice Gets the list of signers who have approved a transaction
   * @param _txHash The hash of the transaction
   * @return _approvedSigners The array of approved signer addresses
   */
  function getApprovedSigners(bytes32 _txHash) external view returns (address[] memory _approvedSigners);
}
