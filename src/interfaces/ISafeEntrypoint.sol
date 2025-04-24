// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ISafeManageable} from 'interfaces/ISafeManageable.sol';
import {IActions} from 'interfaces/actions/IActions.sol';

/**
 * @title ISafeEntrypoint
 * @notice Interface for the SafeEntrypoint contract
 */
interface ISafeEntrypoint is ISafeManageable {
  // ~~~ STRUCTS ~~~

  /**
   * @notice Information about an action
   * @param executableAt The timestamp after which the action can be executed
   * @param actionData The encoded action data
   * @param executed Whether the action has been executed
   * @param actionContracts Array of action contract addresses associated
   */
  struct ActionInfo {
    uint256 executableAt;
    bytes actionData;
    bool executed;
    address[] actionContracts; // Only used for batches
  }

  /**
   * @notice Information about an action contract
   * @param isAllowed Whether the action contract is allowed to be executed
   * @param isQueued Whether the action contract is currently queued for execution
   */
  struct ActionContractInfo {
    bool isAllowed;
    bool isQueued;
  }

  // ~~~ STORAGE METHODS ~~~

  /**
   * @notice Gets the MultiSendCallOnly contract
   * @return _multiSendCallOnly The MultiSendCallOnly contract address
   */
  function MULTI_SEND_CALL_ONLY() external view returns (address _multiSendCallOnly);

  /**
   * @notice Gets the global nonce
   * @return actionNonce The global nonce
   */
  function actionNonce() external view returns (uint256 actionNonce);

  /**
   * @notice Gets the information about an action contract
   * @param _actionContract The address of the action contract
   * @return _isAllowed Whether the action contract is allowed to be executed
   * @return _isQueued Whether the action contract is currently queued for execution
   */
  function getActionContractInfo(address _actionContract) external view returns (bool _isAllowed, bool _isQueued);

  /**
   * @notice Gets the information about an action
   * @param _actionHash The hash of the action
   * @return executableAt The timestamp after which the action can be executed
   * @return actionData The encoded action data
   * @return executed Whether the action has been executed
   * @return actionContracts Array of action contract addresses associated
   */
  function getActionInfo(bytes32 _actionHash)
    external
    view
    returns (uint256 executableAt, bytes memory actionData, bool executed, address[] memory actionContracts);

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
   * @notice Thrown when an action contract is already allowed
   */
  error AlreadyAllowed();

  /**
   * @notice Thrown when an action contract is not allowed
   */
  error NotAllowed();

  /**
   * @notice Thrown when an action is not found
   */
  error ActionNotFound();

  /**
   * @notice Thrown when an action is not executable yet
   */
  error NotExecutable();

  /**
   * @notice Thrown when an action has already been executed
   */
  error ActionAlreadyExecuted();

  /**
   * @notice Thrown when an action contract is already queued
   */
  error ActionAlreadyQueued();

  /**
   * @notice Thrown when an action array is empty
   */
  error EmptyActionsArray();

  /**
   * @notice Thrown when a call to an action contract fails
   */
  error NotSuccess();

  // ~~~ ADMIN METHODS ~~~

  /**
   * @notice Allows an action contract to be executed
   * @dev Can only be called by the Safe contract
   * @param _actionContract The address of the action contract
   */
  function allowAction(address _actionContract) external;

  /**
   * @notice Disallows an action contract from being executed
   * @dev Can only be called by the Safe owners
   * @param _actionContract The address of the action contract
   */
  function disallowAction(address _actionContract) external;

  // ~~~ ACTIONS METHODS ~~~

  /**
   * @notice Queues multiple approved action contracts as a single batch
   * @dev Can only be called by the Safe owners
   * @param _actionContracts Array of action contract addresses to queue
   * @return _actionHash The hash of the queued batch
   */
  function queueApprovedActions(address[] memory _actionContracts) external returns (bytes32 _actionHash);

  /**
   * @notice Queues an arbitrary action for execution
   * @dev Can only be called by the Safe owners
   * @param _actions The array of actions to queue
   * @return _actionHash The hash of the queued action
   */
  function queueArbitraryAction(IActions.Action[] memory _actions) external returns (bytes32 _actionHash);

  /**
   * @notice Executes an action using the approved signers
   * @dev The action must have passed its delay period
   * @param _actionHash The hash of the action to execute
   */
  function executeAction(bytes32 _actionHash) external payable;

  /**
   * @notice Executes an action using the specified signers
   * @dev The action must have passed its delay period
   * @param _actionHash The hash of the action to execute
   * @param _signers The addresses of the signers to use
   */
  function executeAction(bytes32 _actionHash, address[] memory _signers) external payable;

  /**
   * @notice Unqueues an action
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
   * @param _safeNonce The nonce to use
   * @return _safeTxHash The Safe transaction hash
   */
  function getSafeTxHash(address _actionContract, uint256 _safeNonce) external view returns (bytes32 _safeTxHash);

  /**
   * @notice Gets the Safe transaction hash for an action
   * @param _actionHash The hash of the action
   * @return _safeTxHash The Safe transaction hash
   */
  function getSafeTxHash(bytes32 _actionHash) external view returns (bytes32 _safeTxHash);

  /**
   * @notice Gets the Safe transaction hash for an action with a specific nonce
   * @param _actionHash The hash of the action
   * @param _safeNonce The nonce to use
   * @return _safeTxHash The Safe transaction hash
   */
  function getSafeTxHash(bytes32 _actionHash, uint256 _safeNonce) external view returns (bytes32 _safeTxHash);

  /**
   * @notice Gets the approved signers for an action
   * @param _actionHash The hash of the action
   * @return _approvedSigners The array of approved signer addresses
   */
  function getApprovedSigners(bytes32 _actionHash) external view returns (address[] memory _approvedSigners);

  /**
   * @notice Gets the action hash for an action contract with a specific nonce
   * @param _actionContract The address of the action contract
   * @param _actionNonce The nonce to use
   * @return _actionHash The action hash
   */
  function getActionHash(address _actionContract, uint256 _actionNonce) external view returns (bytes32 _actionHash);
}
