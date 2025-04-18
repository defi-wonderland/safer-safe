// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.29;

import {IActions} from 'interfaces/IActions.sol';
import {ISafeManageable} from 'interfaces/ISafeManageable.sol';

/**
 * @title ISafeEntrypoint
 * @notice Interface for the SafeEntrypoint contract
 */
interface ISafeEntrypoint is ISafeManageable {
  // ~~~ STORAGE METHODS ~~~

  /**
   * @notice Returns the address of the MultiSendCallOnly contract
   * @return _multiSendCallOnly The address of the MultiSendCallOnly contract
   */
  function MULTI_SEND_CALL_ONLY() external view returns (address _multiSendCallOnly);

  /**
   * @notice Maps an action contract to its approval status
   * @param _actionContract The address of the action contract
   * @return _isAllowed The approval status of the action contract
   */
  function allowedActions(address _actionContract) external view returns (bool _isAllowed);

  /**
   * @notice Maps an action hash to its executable timestamp
   * @param _actionHash The hash of the action
   * @return _executableAt The timestamp from which the action can be executed
   */
  function actionExecutableAt(bytes32 _actionHash) external view returns (uint256 _executableAt);

  /**
   * @notice Maps an action hash to its data
   * @param _actionHash The hash of the action
   * @return _actionData The data of the action
   */
  function actionData(bytes32 _actionHash) external view returns (bytes memory _actionData);

  /**
   * @notice Maps an action hash to its execution status
   * @param _actionHash The hash of the action
   * @return _executed The execution status of the action
   */
  function executed(bytes32 _actionHash) external view returns (bool _executed);

  // ~~~ EVENTS ~~~

  /**
   * @notice Emitted when an approved action is queued
   * @param _actionHash The hash of the action
   * @param _executableAt The timestamp from which the action can be executed
   */
  event ApprovedActionQueued(bytes32 _actionHash, uint256 _executableAt);

  /**
   * @notice Emitted when an arbitrary action is queued
   * @param _actionHash The hash of the action
   * @param _executableAt The timestamp from which the action can be executed
   */
  event ArbitraryActionQueued(bytes32 _actionHash, uint256 _executableAt);

  /**
   * @notice Emitted when an action is executed
   * @param _actionHash The hash of the action
   * @param _safeTxHash The hash of the Safe transaction
   */
  event ActionExecuted(bytes32 _actionHash, bytes32 _safeTxHash);

  /**
   * @notice Emitted when an action is unqueued
   * @param _actionHash The hash of the action
   */
  event ActionUnqueued(bytes32 _actionHash);

  // ~~~ ERRORS ~~~

  /**
   * @notice Thrown when an action contract is not allowed
   */
  error NotAllowed();

  /**
   * @notice Thrown when an empty actions array is provided
   */
  error EmptyActionsArray();

  /**
   * @notice Thrown when an action is not found
   */
  error ActionNotFound();

  /**
   * @notice Thrown when an action has already been executed
   */
  error ActionAlreadyExecuted();

  /**
   * @notice Thrown when an action is not executable
   */
  error NotExecutable();

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
   * @notice Queues an approved action for execution after a 1-hour delay
   * @dev Can only be called by the Safe owners
   * @dev The action contract must be pre-approved using allowAction
   * @param _actionContract The address of the approved action contract
   */
  function queueApprovedAction(address _actionContract) external returns (bytes32 _actionHash);

  /**
   * @notice Queues arbitrary actions for execution after a 7-day delay
   * @dev Can only be called by the Safe owners
   * @dev The actions must be properly formatted for each target contract
   * @param _actions The array of actions to queue
   */
  function queueArbitraryAction(IActions.Action[] memory _actions) external returns (bytes32 _actionHash);

  /**
   * @notice Executes a queued action using the approved signers
   * @dev The action must have passed its delay period
   * @param _actionHash The hash of the action to execute
   */
  function executeAction(bytes32 _actionHash) external payable;

  /**
   * @notice Executes a queued action using the provided signers
   * @dev The action must have passed its delay period
   * @param _actionHash The hash of the action to execute
   * @param _signers The addresses of the signers to use
   */
  function executeAction(bytes32 _actionHash, address[] memory _signers) external payable;

  /**
   * @notice Unqueues a pending action before it is executed
   * @dev Can only be called by the Safe owners
   * @param _actionHash The hash of the action to unqueue
   */
  function unqueueAction(bytes32 _actionHash) external;

  // ~~~ VIEW METHODS ~~~

  /**
   * @notice Gets the Safe transaction hash for an action contract
   * @param _actionContract The address of the action contract
   * @return _safeTxHash The Safe transaction hash
   */
  function getSafeTxHash(address _actionContract) external view returns (bytes32 _safeTxHash);

  /**
   * @notice Gets the Safe transaction hash for an action contract with a specific nonce
   * @param _actionContract The address of the action contract
   * @param _safeNonce The nonce to use for the hash calculation
   * @return _safeTxHash The Safe transaction hash
   */
  function getSafeTxHash(address _actionContract, uint256 _safeNonce) external view returns (bytes32 _safeTxHash);

  /**
   * @notice Gets the Safe transaction hash for an action hash
   * @param _actionHash The hash of the action
   * @return _safeTxHash The Safe transaction hash
   */
  function getSafeTxHash(bytes32 _actionHash) external view returns (bytes32 _safeTxHash);

  /**
   * @notice Gets the Safe transaction hash for an action hash with a specific nonce
   * @param _actionHash The hash of the action
   * @param _safeNonce The nonce to use for the hash calculation
   * @return _safeTxHash The Safe transaction hash
   */
  function getSafeTxHash(bytes32 _actionHash, uint256 _safeNonce) external view returns (bytes32 _safeTxHash);

  /**
   * @notice Gets the list of signers who have approved a transaction
   * @param _actionHash The hash of the action
   * @return _approvedSigners The array of approved signer addresses
   */
  function getApprovedSigners(bytes32 _actionHash) external view returns (address[] memory _approvedSigners);

  /**
   * @notice Gets the hash of an action from an action contract
   * @param _actionContract The address of the action contract
   * @param _actionNonce The nonce of the action
   * @return _actionHash The hash of the action
   */
  function getActionHash(address _actionContract, uint256 _actionNonce) external view returns (bytes32 _actionHash);
}
