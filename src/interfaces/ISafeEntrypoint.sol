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
   * @notice Action information stored by hash
   */
  struct ActionInfo {
    uint256 executableAt;
    bytes actionData;
    bool executed;
    bool isBatch;
    address[] actionContracts; // Only used for batches
  }

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
   * @notice Maps an action contract to its queued status
   * @param _actionContract The address of the action contract
   * @return _isQueued Whether the action contract is currently queued
   */
  function queuedActions(address _actionContract) external view returns (bool _isQueued);

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
   * @param _actionContract The address of the action contract
   */
  function allowAction(address _actionContract) external;

  /**
   * @notice Disallows an action contract from being executed
   * @param _actionContract The address of the action contract
   */
  function disallowAction(address _actionContract) external;

  /**
   * @notice Resets the queued status of an action contract
   * @param _actionContract The address of the action contract to unqueue
   */
  function unqueueActionContract(address _actionContract) external;

  // ~~~ ACTIONS METHODS ~~~

  /**
   * @notice Queues an approved action for execution
   * @param _actionContract The address of the action contract
   * @return _actionHash The hash of the queued action
   */
  function queueApprovedAction(address _actionContract) external returns (bytes32 _actionHash);

  /**
   * @notice Queues multiple approved action contracts as a single batch
   * @param _actionContracts Array of action contract addresses to queue
   * @return _actionHash The hash of the queued batch
   */
  function queueApprovedActions(address[] memory _actionContracts) external returns (bytes32 _actionHash);

  /**
   * @notice Queues an arbitrary action for execution
   * @param _actions The array of actions to queue
   * @return _actionHash The hash of the queued action
   */
  function queueArbitraryAction(IActions.Action[] memory _actions) external returns (bytes32 _actionHash);

  /**
   * @notice Executes an action using the approved signers
   * @param _actionHash The hash of the action to execute
   */
  function executeAction(bytes32 _actionHash) external payable;

  /**
   * @notice Executes an action using the specified signers
   * @param _actionHash The hash of the action to execute
   * @param _signers The addresses of the signers to use
   */
  function executeAction(bytes32 _actionHash, address[] memory _signers) external payable;

  /**
   * @notice Unqueues an action
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
