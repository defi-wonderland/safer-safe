// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.29;

import {IActions} from 'interfaces/IActions.sol';
import {ISafeManageable} from 'interfaces/ISafeManageable.sol';

interface ISafeEntrypoint is ISafeManageable {
  function MULTI_SEND_CALL_ONLY() external view returns (address _multiSendCallOnly);

  function allowedActions(address _actionContract) external view returns (bool _isAllowed);

  // Mapping for pending actions
  function actionExecutableAt(bytes32 _actionHash) external view returns (uint256 _executableAt);

  // Mapping for pending actions
  function actionData(bytes32 _actionHash) external view returns (bytes memory _actionData);

  // Mapping for executed actions
  function executed(bytes32 _actionHash) external view returns (bool _executed);

  // ~~~ EVENTS ~~~

  event ApprovedActionQueued(bytes32 actionHash, uint256 executableAt);
  event ArbitraryActionQueued(bytes32 actionHash, uint256 executableAt);
  event ActionExecuted(bytes32 actionHash, bytes32 safeTxHash);
  event ActionUnqueued(bytes32 actionHash);

  // ~~~ ERRORS ~~~

  error NotExecutable();
  error NotSuccess();
  error NotAllowed();
  error ActionNotFound();
  error ActionAlreadyExecuted();
  error EmptyActionsArray();

  // ~~~ ADMIN METHODS ~~~

  /**
   * @notice Allows an action contract to be executed by the Safe
   * @dev Can only be called by the Safe contract
   * @param _actionContract The address of the action contract to allow
   */
  function allowAction(address _actionContract) external;

  /**
   * @notice Disallows an action contract from being executed by the Safe
   * @dev Can be called by any authorized address (safe owner)
   * @param _actionContract The address of the action contract to disallow
   */
  function disallowAction(address _actionContract) external;

  // ~~~ ACTIONS METHODS ~~~

  /**
   * @notice Queues an approved action for execution after a 1-hour delay
   * @dev The action contract must be pre-approved using allowAction
   * @param _actionContract The address of the approved action contract
   */
  function queueApprovedAction(address _actionContract) external returns (bytes32 _actionHash);

  /**
   * @notice Queues arbitrary actions for execution after a 7-day delay
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
   * @dev Can only be called by authorized addresses (safe owners)
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
