// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {SafeManageable} from 'contracts/SafeManageable.sol';

import {ISafeEntrypoint} from 'interfaces/ISafeEntrypoint.sol';
import {IActions} from 'interfaces/actions/IActions.sol';

import {Enum} from '@safe-smart-account/libraries/Enum.sol';
import {MultiSendCallOnly} from '@safe-smart-account/libraries/MultiSendCallOnly.sol';

/**
 * @title SafeEntrypoint
 * @notice Contract that allows for the execution of actions on a Safe
 */
contract SafeEntrypoint is SafeManageable, ISafeEntrypoint {
  /// @inheritdoc ISafeEntrypoint
  address public immutable MULTI_SEND_CALL_ONLY;

  /// @inheritdoc ISafeEntrypoint
  uint256 public actionNonce;

  /// @inheritdoc ISafeEntrypoint
  mapping(address _actionContract => bool _isAllowed) public allowedActions;

  /// @inheritdoc ISafeEntrypoint
  mapping(address _actionContract => bool _isQueued) public queuedActions;

  /**
   * @notice Maps an action hash to its information
   */
  mapping(bytes32 _actionHash => ActionInfo _info) public actions;

  /**
   * @notice Constructor that sets up the Safe and MultiSendCallOnly contracts
   * @param _safe The Gnosis Safe contract address
   * @param _multiSendCallOnly The MultiSendCallOnly contract address
   */
  constructor(address _safe, address _multiSendCallOnly) SafeManageable(_safe) {
    MULTI_SEND_CALL_ONLY = _multiSendCallOnly;
  }

  // ~~~ ADMIN METHODS ~~~

  /// @inheritdoc ISafeEntrypoint
  function allowAction(address _actionContract) external isMsig {
    allowedActions[_actionContract] = true;
  }

  /// @inheritdoc ISafeEntrypoint
  function disallowAction(address _actionContract) external isAuthorized {
    allowedActions[_actionContract] = false;
  }

  // ~~~ ACTIONS METHODS ~~~

  /// @inheritdoc ISafeEntrypoint
  function queueApprovedAction(address _actionContract) external isAuthorized returns (bytes32 _actionHash) {
    address[] memory _actionContracts = new address[](1);
    _actionContracts[0] = _actionContract;
    return queueApprovedActions(_actionContracts);
  }

  /// @inheritdoc ISafeEntrypoint
  function queueApprovedActions(address[] memory _actionContracts) public isAuthorized returns (bytes32 _actionHash) {
    // Validate input array is not empty
    if (_actionContracts.length == 0) revert EmptyActionsArray();

    // Validate all contracts are allowed and not already queued
    for (uint256 _i; _i < _actionContracts.length; ++_i) {
      if (!allowedActions[_actionContracts[_i]]) revert NotAllowed();
      if (queuedActions[_actionContracts[_i]]) revert ActionAlreadyQueued();
    }

    // Collect all actions
    IActions.Action[] memory allActions = _collectActions(_actionContracts);

    // Create a unique hash for the batch
    _actionHash = keccak256(abi.encode(allActions, actionNonce++));

    // Mark all contracts as queued
    for (uint256 _i; _i < _actionContracts.length; ++_i) {
      queuedActions[_actionContracts[_i]] = true;
    }

    // Store the batch information
    actions[_actionHash] = ActionInfo({
      executableAt: block.timestamp + 1 hours,
      actionData: abi.encode(allActions),
      executed: false,
      actionContracts: _actionContracts
    });

    // NOTE: event picked up by off-chain monitoring service
    emit ApprovedActionQueued(_actionHash, block.timestamp + 1 hours);
  }

  /// @inheritdoc ISafeEntrypoint
  function queueArbitraryAction(IActions.Action[] memory _actions) external isAuthorized returns (bytes32 _actionHash) {
    // Validate that the actions array is not empty
    if (_actions.length == 0) {
      revert EmptyActionsArray();
    }

    // Create a unique hash for the actions
    _actionHash = keccak256(abi.encode(_actions, actionNonce++));

    // Store the action information
    actions[_actionHash] = ActionInfo({
      executableAt: block.timestamp + 7 days,
      actionData: abi.encode(_actions),
      executed: false,
      actionContracts: new address[](0)
    });

    // NOTE: event picked up by off-chain monitoring service
    emit ArbitraryActionQueued(_actionHash, block.timestamp + 7 days);
  }

  /// @inheritdoc ISafeEntrypoint
  function executeAction(bytes32 _actionHash) external payable {
    _executeAction(_actionHash, _getApprovedSigners(_actionHash));
  }

  /// @inheritdoc ISafeEntrypoint
  function executeAction(bytes32 _actionHash, address[] memory _signers) external payable {
    _executeAction(_actionHash, _signers);
  }

  /// @inheritdoc ISafeEntrypoint
  function unqueueAction(bytes32 _actionHash) external isAuthorized {
    // Check if the action exists
    if (actions[_actionHash].executableAt == 0) revert ActionNotFound();

    // Check if the action has already been executed
    if (actions[_actionHash].executed) revert ActionAlreadyExecuted();

    // Unqueue all action contracts
    address[] memory actionContracts = actions[_actionHash].actionContracts;
    for (uint256 i = 0; i < actionContracts.length; i++) {
      queuedActions[actionContracts[i]] = false;
    }

    // Clear the action data
    delete actions[_actionHash];

    // Emit event for off-chain monitoring
    emit ActionUnqueued(_actionHash);
  }

  // ~~~ VIEW METHODS ~~~

  /// @inheritdoc ISafeEntrypoint
  function getSafeTxHash(address _actionContract) external view returns (bytes32 _safeTxHash) {
    IActions.Action[] memory _actions = _fetchActions(_actionContract);
    bytes memory _multiSendData = _constructMultiSendData(_actions);
    _safeTxHash = _getSafeTxHash(_multiSendData, SAFE.nonce());
  }

  /// @inheritdoc ISafeEntrypoint
  function getSafeTxHash(address _actionContract, uint256 _safeNonce) external view returns (bytes32 _safeTxHash) {
    IActions.Action[] memory _actions = _fetchActions(_actionContract);
    bytes memory _multiSendData = _constructMultiSendData(_actions);
    _safeTxHash = _getSafeTxHash(_multiSendData, _safeNonce);
  }

  /// @inheritdoc ISafeEntrypoint
  function getSafeTxHash(bytes32 _actionHash) external view returns (bytes32 _safeTxHash) {
    IActions.Action[] memory _actions = abi.decode(actions[_actionHash].actionData, (IActions.Action[]));
    bytes memory _multiSendData = _constructMultiSendData(_actions);
    _safeTxHash = _getSafeTxHash(_multiSendData, SAFE.nonce());
  }

  /// @inheritdoc ISafeEntrypoint
  function getSafeTxHash(bytes32 _actionHash, uint256 _safeNonce) external view returns (bytes32 _safeTxHash) {
    bytes memory _multiSendData =
      _constructMultiSendData(abi.decode(actions[_actionHash].actionData, (IActions.Action[])));
    _safeTxHash = _getSafeTxHash(_multiSendData, _safeNonce);
  }

  /// @inheritdoc ISafeEntrypoint
  function getApprovedSigners(bytes32 _actionHash) external view returns (address[] memory _approvedSigners) {
    _approvedSigners = _getApprovedSigners(_actionHash);
  }

  /// @inheritdoc ISafeEntrypoint
  function getActionHash(address _actionContract, uint256 _actionNonce) external view returns (bytes32 _actionHash) {
    IActions.Action[] memory actionList = _fetchActions(_actionContract);
    _actionHash = keccak256(abi.encode(actionList, _actionNonce));
  }

  // ~~~ INTERNAL METHODS ~~~

  /**
   * @notice Internal function to execute an action
   * @dev Checks if the action is executable and constructs the necessary data
   * @param _actionHash The hash of the action to execute
   * @param _signers The addresses of the signers to use
   */
  function _executeAction(bytes32 _actionHash, address[] memory _signers) internal {
    ActionInfo storage actionInfo = actions[_actionHash];

    if (actionInfo.executableAt > block.timestamp) revert NotExecutable();
    if (actionInfo.executed) revert ActionAlreadyExecuted();

    bytes memory _multiSendData = _constructMultiSendData(abi.decode(actionInfo.actionData, (IActions.Action[])));
    address[] memory _sortedSigners = _sortSigners(_signers);
    bytes memory _signatures = _constructApprovedHashSignatures(_sortedSigners);

    // NOTE: only for event logging
    uint256 _safeNonce = SAFE.nonce();
    bytes32 _safeTxHash = _getSafeTxHash(_multiSendData, _safeNonce);
    _execSafeTx(_multiSendData, _signatures);

    // Mark the action as executed
    actionInfo.executed = true;

    // Unqueue all action contracts
    address[] memory actionContracts = actionInfo.actionContracts;
    for (uint256 i = 0; i < actionContracts.length; i++) {
      queuedActions[actionContracts[i]] = false;
    }

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
   * @return _actions The array of actions
   */
  function _fetchActions(address _actionContract) internal view returns (IActions.Action[] memory _actions) {
    // Encode the function call for getActions()
    bytes memory _callData = abi.encodeWithSelector(IActions.getActions.selector, bytes(''));

    // Make a static call (executes the code but reverts any state changes)
    (bool _success, bytes memory _returnData) = _actionContract.staticcall(_callData);

    // If the call succeeded, decode the returned data
    if (_success && _returnData.length > 0) {
      _actions = abi.decode(_returnData, (IActions.Action[]));
    } else {
      revert NotSuccess();
    }
  }

  /**
   * @notice Internal function to collect actions from multiple contracts
   * @param _actionContracts Array of action contract addresses
   * @return _allActions Combined array of all actions
   */
  function _collectActions(address[] memory _actionContracts)
    internal
    view
    returns (IActions.Action[] memory _allActions)
  {
    // Cache for storing actions from each contract
    IActions.Action[][] memory _cachedActions = new IActions.Action[][](_actionContracts.length);
    uint256 _totalLength;

    // First pass: call getActions once per contract and cache the results
    for (uint256 _i; _i < _actionContracts.length; ++_i) {
      address _actionContract = _actionContracts[_i];
      IActions.Action[] memory actionList = _fetchActions(_actionContract);
      _cachedActions[_i] = actionList;
      _totalLength += actionList.length;
    }

    // Allocate the final array
    _allActions = new IActions.Action[](_totalLength);

    // Second pass: fill the final array from cached results
    uint256 _index;
    for (uint256 _i; _i < _cachedActions.length; ++_i) {
      for (uint256 _j; _j < _cachedActions[_i].length; ++_j) {
        _allActions[_index++] = _cachedActions[_i][_j];
      }
    }

    return _allActions;
  }

  /**
   * @notice Internal function to get the Safe transaction hash
   * @param _data The transaction data
   * @param _safeNonce The nonce to use
   * @return _safeTxHash The Safe transaction hash
   */
  function _getSafeTxHash(bytes memory _data, uint256 _safeNonce) internal view returns (bytes32 _safeTxHash) {
    _safeTxHash = SAFE.getTransactionHash({
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

    bytes memory _multiSendData =
      _constructMultiSendData(abi.decode(actions[_actionHash].actionData, (IActions.Action[])));
    bytes32 _safeTxHash = _getSafeTxHash(_multiSendData, SAFE.nonce());

    // Create a temporary array to store approved signers
    address[] memory _tempApproved = new address[](_signers.length);
    uint256 _approvedCount = 0;

    // Single pass through all signers
    for (uint256 _i; _i < _signers.length; ++_i) {
      // Check if this signer has approved the hash
      if (SAFE.approvedHashes(_signers[_i], _safeTxHash) == 1) {
        _tempApproved[_approvedCount] = _signers[_i];
        ++_approvedCount;
      }
    }

    // Create the final result array with the exact size needed
    _approvedSigners = new address[](_approvedCount);

    // Copy from temporary array to final array
    for (uint256 _i; _i < _approvedCount; ++_i) {
      _approvedSigners[_i] = _tempApproved[_i];
    }
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
    for (uint256 _i; _i < _actions.length; ++_i) {
      // Extract the current action
      IActions.Action memory _action = _actions[_i];

      // For each action, we encode:
      // 1 byte: operation (0 = Call, 1 = DelegateCall) - using 0 (Call) by default
      // 20 bytes: target address
      // 32 bytes: ether value
      // 32 bytes: data length
      // N bytes: data payload

      // Encode each action using abi.encodePacked to avoid padding
      bytes memory _encodedAction = abi.encodePacked(
        uint8(0), // operation (0 = Call)
        _action.target, // target address
        _action.value, // ether value
        uint256(_action.data.length), // data length
        _action.data // data payload
      );

      // Append the encoded action to the multiSendData
      _multiSendData = abi.encodePacked(_multiSendData, _encodedAction);
    }

    _multiSendData = abi.encodeWithSelector(MultiSendCallOnly.multiSend.selector, _multiSendData);
  }

  /**
   * @notice Internal function to sort signer addresses
   * @dev Uses bubble sort to sort addresses numerically
   * @param _signers The array of signer addresses to sort
   * @return _sortedSigners The sorted array of signer addresses
   */
  function _sortSigners(address[] memory _signers) internal pure returns (address[] memory _sortedSigners) {
    for (uint256 _i; _i < _signers.length; ++_i) {
      for (uint256 _j; _j < _signers.length - _i - 1; ++_j) {
        // If the current element is greater than the next element, swap them
        if (_signers[_j] > _signers[_j + 1]) {
          // Swap elements
          address _temp = _signers[_j];
          _signers[_j] = _signers[_j + 1];
          _signers[_j + 1] = _temp;
        }
      }
    }

    return _signers;
  }

  /**
   * @notice Internal function to construct signatures for approved hashes
   * @dev Creates a special signature format using the signer's address
   * @param _signers The array of signer addresses
   * @return _signatures The encoded signatures
   */
  function _constructApprovedHashSignatures(address[] memory _signers) internal pure returns (bytes memory _signatures) {
    // Each signature requires exactly 65 bytes:
    // r: 32 bytes
    // s: 32 bytes
    // v: 1 byte

    // The total length will be signers.length * 65 bytes
    _signatures = new bytes(_signers.length * 65);

    for (uint256 _i; _i < _signers.length; ++_i) {
      // Calculate position in the signatures array (65 bytes per signature)
      uint256 _pos = 65 * _i;

      // Set r to the signer address (converted to bytes32)
      bytes32 _r = bytes32(uint256(uint160(_signers[_i])));

      // Set s to zero (not used for approved hash validation)
      bytes32 _s = bytes32(0);

      // Set v to 1 (indicates this is an approved hash signature)
      uint8 _v = 1;

      // Write the signature values to the byte array
      assembly {
        // r value: first 32 bytes of the signature
        mstore(add(add(_signatures, 32), _pos), _r)

        // s value: next 32 bytes of the signature
        mstore(add(add(_signatures, 32), add(_pos, 32)), _s)

        // v value: final 1 byte of the signature
        mstore8(add(add(_signatures, 32), add(_pos, 64)), _v)
      }
    }
  }
}
