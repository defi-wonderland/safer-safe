// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.29;

import {IActions} from 'interfaces/IActions.sol';

import {SafeManageable} from 'contracts/SafeManageable.sol';

import {Enum} from '@safe-smart-account/libraries/Enum.sol';
import {MultiSendCallOnly} from '@safe-smart-account/libraries/MultiSendCallOnly.sol';

contract SafeEntrypoint is SafeManageable {
  address public immutable MULTI_SEND_CALL_ONLY;

  // Global nonce to ensure unique hashes for identical actions
  uint256 internal _nonce;

  mapping(address _actionContract => bool _isAllowed) public allowedActions;

  // Mapping for pending actions
  mapping(bytes32 _actionHash => uint256 _executableAt) public actionExecutableAt;
  // Mapping for pending actions
  mapping(bytes32 _actionHash => bytes _actionData) public actionData;
  // Mapping for executed actions
  mapping(bytes32 _actionHash => bool _executed) public executed;

  event ApprovedActionQueued(bytes32 actionHash, uint256 executableAt);
  event ArbitraryActionQueued(bytes32 actionHash, uint256 executableAt);
  event ActionExecuted(bytes32 actionHash, bytes32 safeTxHash);
  event ActionUnqueued(bytes32 actionHash);

  error NotExecutable();
  error NotSuccess();
  error NotAllowed();
  error ActionNotFound();
  error ActionAlreadyExecuted();
  error EmptyActionsArray();

  /**
   * @notice Constructor that sets up the Safe and MultiSend contracts
   * @param _safe The Gnosis Safe contract address
   * @param _multiSend The MultiSend contract address
   */
  constructor(address _safe, address _multiSend) SafeManageable(_safe) {
    MULTI_SEND_CALL_ONLY = _multiSend;
  }

  // ~~~ ADMIN METHODS ~~~

  /**
   * @notice Allows an action contract to be executed by the Safe
   * @dev Can only be called by the Safe contract
   * @param _actionContract The address of the action contract to allow
   */
  function allowAction(address _actionContract) external isMsig {
    allowedActions[_actionContract] = true;
  }

  /**
   * @notice Disallows an action contract from being executed by the Safe
   * @dev Can be called by any authorized address (safe owner)
   * @param _actionContract The address of the action contract to disallow
   */
  function disallowAction(address _actionContract) external isAuthorized {
    allowedActions[_actionContract] = false;
  }

  // ~~~ ACTIONS METHODS ~~~

  /**
   * @notice Queues an approved action for execution after a 1-hour delay
   * @dev The action contract must be pre-approved using allowAction
   * @param _actionContract The address of the approved action contract
   */
  function queueApprovedAction(address _actionContract) external isAuthorized returns (bytes32 _actionHash) {
    if (!allowedActions[_actionContract]) revert NotAllowed();

    IActions.Action[] memory actions = IActions(_actionContract).getActions();
    _actionHash = keccak256(abi.encode(actions, _nonce++));

    uint256 _executableAt = block.timestamp + 1 hours;
    actionExecutableAt[_actionHash] = _executableAt;
    actionData[_actionHash] = abi.encode(actions);

    // NOTE: event picked up by off-chain monitoring service
    emit ApprovedActionQueued(_actionHash, _executableAt);

    return _actionHash;
  }

  /**
   * @notice Queues arbitrary actions for execution after a 7-day delay
   * @dev The actions must be properly formatted for each target contract
   * @param _actions The array of actions to queue
   */
  function queueArbitraryAction(IActions.Action[] memory _actions) external isAuthorized returns (bytes32 _actionHash) {
    // Validate that the actions array is not empty
    if (_actions.length == 0) {
      revert EmptyActionsArray();
    }

    // Use the existing action storage mechanism
    _actionHash = keccak256(abi.encode(_actions, _nonce++));
    uint256 _executableAt = block.timestamp + 7 days;
    actionExecutableAt[_actionHash] = _executableAt;
    actionData[_actionHash] = abi.encode(_actions);

    // NOTE: event picked up by off-chain monitoring service
    emit ArbitraryActionQueued(_actionHash, _executableAt);

    return _actionHash;
  }

  /**
   * @notice Executes a queued action using the approved signers
   * @dev The action must have passed its delay period
   * @param _actionHash The hash of the action to execute
   */
  function executeAction(bytes32 _actionHash) external payable {
    _executeAction(_actionHash, _getApprovedSigners(_actionHash));
  }

  /**
   * @notice Executes a queued action using the provided signers
   * @dev The action must have passed its delay period
   * @param _actionHash The hash of the action to execute
   * @param _signers The addresses of the signers to use
   */
  function executeAction(bytes32 _actionHash, address[] memory _signers) external payable {
    _executeAction(_actionHash, _signers);
  }

  /**
   * @notice Unqueues a pending action before it is executed
   * @dev Can only be called by authorized addresses (safe owners)
   * @param _actionHash The hash of the action to unqueue
   */
  function unqueueAction(bytes32 _actionHash) external isAuthorized {
    // Check if the action exists
    if (actionExecutableAt[_actionHash] == 0) revert ActionNotFound();

    // Check if the action has already been executed
    if (executed[_actionHash]) revert ActionAlreadyExecuted();

    // Clear the action data
    delete actionExecutableAt[_actionHash];
    delete actionData[_actionHash];

    // Emit event for off-chain monitoring
    emit ActionUnqueued(_actionHash);
  }

  // ~~~ VIEW METHODS ~~~

  /**
   * @notice Gets the Safe transaction hash for an action contract
   * @param _actionContract The address of the action contract
   * @return _safeTxHash The Safe transaction hash
   */
  function getSafeTxHash(address _actionContract) external view returns (bytes32 _safeTxHash) {
    IActions.Action[] memory _actions = _fetchActions(_actionContract);
    bytes memory _multiSendData = _constructMultiSendData(_actions);
    _safeTxHash = _getSafeTxHash(_multiSendData, SAFE.nonce());
  }

  /**
   * @notice Gets the Safe transaction hash for an action contract with a specific nonce
   * @param _actionContract The address of the action contract
   * @param _safeNonce The nonce to use for the hash calculation
   * @return _safeTxHash The Safe transaction hash
   */
  function getSafeTxHash(address _actionContract, uint256 _safeNonce) external view returns (bytes32 _safeTxHash) {
    IActions.Action[] memory _actions = _fetchActions(_actionContract);
    bytes memory _multiSendData = _constructMultiSendData(_actions);
    _safeTxHash = _getSafeTxHash(_multiSendData, _safeNonce);
  }

  /**
   * @notice Gets the Safe transaction hash for an action hash
   * @param _actionHash The hash of the action
   * @return _safeTxHash The Safe transaction hash
   */
  function getSafeTxHash(bytes32 _actionHash) external view returns (bytes32 _safeTxHash) {
    IActions.Action[] memory _actions = abi.decode(actionData[_actionHash], (IActions.Action[]));
    bytes memory _multiSendData = _constructMultiSendData(_actions);
    _safeTxHash = _getSafeTxHash(_multiSendData, SAFE.nonce());
  }

  /**
   * @notice Gets the Safe transaction hash for an action hash with a specific nonce
   * @param _actionHash The hash of the action
   * @param _safeNonce The nonce to use for the hash calculation
   * @return _safeTxHash The Safe transaction hash
   */
  function getSafeTxHash(bytes32 _actionHash, uint256 _safeNonce) external view returns (bytes32 _safeTxHash) {
    bytes memory _multiSendData = _constructMultiSendData(abi.decode(actionData[_actionHash], (IActions.Action[])));
    _safeTxHash = _getSafeTxHash(_multiSendData, _safeNonce);
  }

  /**
   * @notice Gets the list of signers who have approved a transaction
   * @param _actionHash The hash of the action
   * @return _approvedSigners The array of approved signer addresses
   */
  function getApprovedSigners(bytes32 _actionHash) external view returns (address[] memory _approvedSigners) {
    _approvedSigners = _getApprovedSigners(_actionHash);
  }

  /**
   * @notice Gets the hash of an action from an action contract
   * @param _actionContract The address of the action contract
   * @param _actionNonce The nonce of the action
   * @return _actionHash The hash of the action
   */
  function getActionHash(address _actionContract, uint256 _actionNonce) external view returns (bytes32 _actionHash) {
    IActions.Action[] memory actions = _fetchActions(_actionContract);
    _actionHash = keccak256(abi.encode(actions, _actionNonce));
  }

  // ~~~ INTERNAL METHODS ~~~

  /**
   * @notice Internal function to execute an action
   * @dev Checks if the action is executable and constructs the necessary data
   * @param _actionHash The hash of the action to execute
   * @param _signers The addresses of the signers to use
   */
  function _executeAction(bytes32 _actionHash, address[] memory _signers) internal {
    if (actionExecutableAt[_actionHash] > block.timestamp) revert NotExecutable();
    if (executed[_actionHash]) revert ActionAlreadyExecuted();

    bytes memory _multiSendData = _constructMultiSendData(abi.decode(actionData[_actionHash], (IActions.Action[])));
    address[] memory _sortedSigners = _sortSigners(_signers);
    bytes memory _signatures = _constructApprovedHashSignatures(_sortedSigners);

    // NOTE: only for event logging
    uint256 _safeNonce = SAFE.nonce();
    bytes32 _safeTxHash = _getSafeTxHash(_multiSendData, _safeNonce);
    _execSafeTx(_multiSendData, _signatures);

    // Mark the action as executed
    executed[_actionHash] = true;

    // NOTE: event emitted to log successful execution
    emit ActionExecuted(_actionHash, _safeTxHash);
  }

  /**
   * @notice Internal function to execute a Safe transaction
   * @dev Uses the Safe's execTransaction function
   * @param _data The transaction data
   * @param _signatures The signatures for the transaction
   */
  function _execSafeTx(bytes memory _data, bytes memory _signatures) internal {
    SAFE.execTransaction{value: msg.value}({
      to: MULTI_SEND_CALL_ONLY,
      value: 0,
      data: _data,
      operation: Enum.Operation.DelegateCall,
      safeTxGas: 0,
      baseGas: 0,
      gasPrice: 0,
      gasToken: address(0),
      refundReceiver: payable(address(this)),
      signatures: _signatures
    });
  }

  /**
   * @notice Internal function to fetch actions from a contract
   * @dev Uses staticcall to prevent state changes
   * @param _actionContract The address of the action contract
   * @return actions The array of actions
   */
  function _fetchActions(address _actionContract) internal view returns (IActions.Action[] memory actions) {
    // Encode the function call for getActions()
    bytes memory _callData = abi.encodeWithSelector(IActions.getActions.selector, bytes(''));

    // Make a static call (executes the code but reverts any state changes)
    bytes memory _returnData;
    bool _success;
    (_success, _returnData) = _actionContract.staticcall(_callData);

    // If the call succeeded, decode the returned data
    if (_success && _returnData.length > 0) {
      actions = abi.decode(_returnData, (IActions.Action[]));
    } else {
      revert NotSuccess();
    }

    return actions;
  }

  /**
   * @notice Internal function to get the Safe transaction hash
   * @param _data The transaction data
   * @param _safeNonce The nonce to use
   * @return The Safe transaction hash
   */
  function _getSafeTxHash(bytes memory _data, uint256 _safeNonce) internal view returns (bytes32) {
    return SAFE.getTransactionHash({
      to: MULTI_SEND_CALL_ONLY,
      value: 0,
      data: _data,
      operation: Enum.Operation.DelegateCall,
      safeTxGas: 0,
      baseGas: 0,
      gasPrice: 0,
      gasToken: address(0),
      refundReceiver: payable(address(this)),
      _nonce: _safeNonce
    });
  }

  /**
   * @notice Internal function to get the list of approved signers for a transaction
   * @param _actionHash The hash of the action
   * @return _approvedSigners The array of approved signer addresses
   */
  function _getApprovedSigners(bytes32 _actionHash) internal view returns (address[] memory _approvedSigners) {
    address[] memory _signers = SAFE.getOwners();

    bytes memory _multiSendData = _constructMultiSendData(abi.decode(actionData[_actionHash], (IActions.Action[])));
    bytes32 _txHash = _getSafeTxHash(_multiSendData, SAFE.nonce());

    // Create a temporary array to store approved signers
    address[] memory tempApproved = new address[](_signers.length);
    uint256 approvedCount = 0;

    // Single pass through all signers
    for (uint256 i = 0; i < _signers.length; i++) {
      // Check if this signer has approved the hash
      if (SAFE.approvedHashes(_signers[i], _txHash) == 1) {
        tempApproved[approvedCount] = _signers[i];
        approvedCount++;
      }
    }

    // Create the final result array with the exact size needed
    _approvedSigners = new address[](approvedCount);

    // Copy from temporary array to final array
    for (uint256 i = 0; i < approvedCount; i++) {
      _approvedSigners[i] = tempApproved[i];
    }

    return _approvedSigners;
  }

  // ~~~ INTERNAL PURE METHODS ~~~

  /**
   * @notice Internal function to construct MultiSend data from actions
   * @dev Encodes each action into the MultiSend format
   * @param _actions The array of actions to encode
   * @return _multiSendData The encoded MultiSend data
   */
  function _constructMultiSendData(IActions.Action[] memory _actions)
    internal
    pure
    returns (bytes memory _multiSendData)
  {
    // Initialize an empty bytes array to avoid null reference
    _multiSendData = new bytes(0);

    // Loop through each action and encode it
    for (uint256 i = 0; i < _actions.length; i++) {
      // Extract the current action
      IActions.Action memory action = _actions[i];

      // For each action, we encode:
      // 1 byte: operation (0 = Call, 1 = DelegateCall) - using 0 (Call) by default
      // 20 bytes: target address
      // 32 bytes: ether value
      // 32 bytes: data length
      // N bytes: data payload

      // Encode each action using abi.encodePacked to avoid padding
      bytes memory encodedAction = abi.encodePacked(
        uint8(0), // operation (0 = Call)
        action.target, // target address
        action.value, // ether value
        uint256(action.data.length), // data length
        action.data // data payload
      );

      // Append the encoded action to the multiSendData
      _multiSendData = abi.encodePacked(_multiSendData, encodedAction);
    }

    _multiSendData = abi.encodeWithSelector(MultiSendCallOnly.multiSend.selector, _multiSendData);

    return _multiSendData;
  }

  /**
   * @notice Internal function to sort signer addresses
   * @dev Uses bubble sort to sort addresses numerically
   * @param _signers The array of signer addresses to sort
   * @return The sorted array of signer addresses
   */
  function _sortSigners(address[] memory _signers) internal pure returns (address[] memory) {
    for (uint256 i = 0; i < _signers.length; i++) {
      for (uint256 j = 0; j < _signers.length - i - 1; j++) {
        // If the current element is greater than the next element, swap them
        if (_signers[j] > _signers[j + 1]) {
          // Swap elements
          address temp = _signers[j];
          _signers[j] = _signers[j + 1];
          _signers[j + 1] = temp;
        }
      }
    }

    return _signers;
  }

  /**
   * @notice Internal function to construct signatures for approved hashes
   * @dev Creates a special signature format using the signer's address
   * @param _signers The array of signer addresses
   * @return The encoded signatures
   */
  function _constructApprovedHashSignatures(address[] memory _signers) internal pure returns (bytes memory) {
    // Each signature requires exactly 65 bytes:
    // r: 32 bytes
    // s: 32 bytes
    // v: 1 byte

    // The total length will be signers.length * 65 bytes
    bytes memory signatures = new bytes(_signers.length * 65);

    for (uint256 i = 0; i < _signers.length; i++) {
      // Calculate position in the signatures array (65 bytes per signature)
      uint256 pos = 65 * i;

      // Set r to the signer address (converted to bytes32)
      bytes32 r = bytes32(uint256(uint160(_signers[i])));

      // Set s to zero (not used for approved hash validation)
      bytes32 s = bytes32(0);

      // Set v to 1 (indicates this is an approved hash signature)
      uint8 v = 1;

      // Write the signature values to the byte array
      assembly {
        // r value: first 32 bytes of the signature
        mstore(add(add(signatures, 32), pos), r)

        // s value: next 32 bytes of the signature
        mstore(add(add(signatures, 32), add(pos, 32)), s)

        // v value: final 1 byte of the signature
        mstore8(add(add(signatures, 32), add(pos, 64)), v)
      }
    }

    return signatures;
  }
}
