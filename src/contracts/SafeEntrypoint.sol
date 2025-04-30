// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {SafeManageable} from 'contracts/SafeManageable.sol';

import {ISafeEntrypoint} from 'interfaces/ISafeEntrypoint.sol';
import {IActionsBuilder} from 'interfaces/actions/IActionsBuilder.sol';

import {Enum} from '@safe-smart-account/libraries/Enum.sol';
import {MultiSendCallOnly} from '@safe-smart-account/libraries/MultiSendCallOnly.sol';

/**
 * @title SafeEntrypoint
 * @notice Contract that allows for the execution of transactions on a Safe
 */
contract SafeEntrypoint is SafeManageable, ISafeEntrypoint {
  // ~~~ STORAGE ~~~

  /// @inheritdoc ISafeEntrypoint
  address public immutable MULTI_SEND_CALL_ONLY;

  /// @inheritdoc ISafeEntrypoint
  uint256 public transactionNonce;

  /// @notice Maps an actions builder to its information
  mapping(address _actionsBuilder => ActionsBuilderInfo _actionsBuilderInfo) internal _actionsBuilderInfo;

  /// @notice Maps a transaction ID to its information
  mapping(uint256 _txId => TransactionInfo _txInfo) internal _transactionInfo;

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
  function approveActionsBuilder(address _actionsBuilder, uint256 _approvalDuration) external isSafe {
    uint256 _approvalExpiryTime = block.timestamp + _approvalDuration;

    _actionsBuilderInfo[_actionsBuilder].approvalExpiryTime = _approvalExpiryTime;
    emit ActionsBuilderApproved(_actionsBuilder, _approvalDuration, _approvalExpiryTime);
  }

  // ~~~ TRANSACTION METHODS ~~~

  /// @inheritdoc ISafeEntrypoint
  function queueTransaction(address[] memory _actionsBuilders) external isSafeOwner returns (uint256 _txId) {
    // Validate input array is not empty
    if (_actionsBuilders.length == 0) revert EmptyActionsBuildersArray();

    // Validate all contracts are allowed and not already queued
    for (uint256 _i; _i < _actionsBuilders.length; ++_i) {
      if (_actionsBuilderInfo[_actionsBuilders[_i]].approvalExpiryTime <= block.timestamp) {
        revert ActionsBuilderNotApproved();
      }
      if (_actionsBuilderInfo[_actionsBuilders[_i]].isQueued) revert ActionsBuilderAlreadyQueued();

      _actionsBuilderInfo[_actionsBuilders[_i]].isQueued = true;
    }

    // Collect all actions
    IActionsBuilder.Action[] memory _allActions = _collectActions(_actionsBuilders);

    // Generate a simple transaction ID
    _txId = transactionNonce++;

    // Store the transaction information
    _transactionInfo[_txId] = TransactionInfo({
      actionsBuilders: _actionsBuilders,
      actionsData: abi.encode(_allActions),
      executableAt: block.timestamp + 1 hours,
      isExecuted: false
    });

    // NOTE: event picked up by off-chain monitoring service
    emit TransactionQueued(_txId, block.timestamp + 1 hours, false);
  }

  /// @inheritdoc ISafeEntrypoint
  function queueTransaction(IActionsBuilder.Action[] memory _actions) external isSafeOwner returns (uint256 _txId) {
    // Validate that the actions array is not empty
    if (_actions.length == 0) {
      revert EmptyActionsArray();
    }

    // Generate a simple transaction ID
    _txId = transactionNonce++;

    // Store the transaction information
    _transactionInfo[_txId] = TransactionInfo({
      actionsBuilders: new address[](0),
      actionsData: abi.encode(_actions),
      executableAt: block.timestamp + 7 days,
      isExecuted: false
    });

    // NOTE: event picked up by off-chain monitoring service
    emit TransactionQueued(_txId, block.timestamp + 7 days, true);
  }

  /// @inheritdoc ISafeEntrypoint
  function executeTransaction(uint256 _txId) external payable {
    _executeTransaction(_txId, _getApprovedHashSigners(_txId));
  }

  /// @inheritdoc ISafeEntrypoint
  function executeTransaction(uint256 _txId, address[] memory _signers) external payable {
    _executeTransaction(_txId, _signers);
  }

  /// @inheritdoc ISafeEntrypoint
  function unqueueTransaction(uint256 _txId) external isSafeOwner {
    // Check if the transaction exists
    if (_transactionInfo[_txId].executableAt == 0) revert TransactionNotQueued();

    // Check if the transaction has already been executed
    if (_transactionInfo[_txId].isExecuted) revert TransactionAlreadyExecuted();

    // Unqueue all actions builders
    address[] memory _actionsBuildersToUnqueue = _transactionInfo[_txId].actionsBuilders;
    for (uint256 _i; _i < _actionsBuildersToUnqueue.length; ++_i) {
      _actionsBuilderInfo[_actionsBuildersToUnqueue[_i]].isQueued = false;
    }

    // Clear the transaction information
    delete _transactionInfo[_txId];

    // Emit event for off-chain monitoring
    emit TransactionUnqueued(_txId);
  }

  // ~~~ EXTERNAL VIEW METHODS ~~~

  /// @inheritdoc ISafeEntrypoint
  function getActionsBuilderInfo(address _actionsBuilder)
    external
    view
    returns (uint256 _approvalExpiryTime, bool _isQueued)
  {
    (_approvalExpiryTime, _isQueued) =
      (_actionsBuilderInfo[_actionsBuilder].approvalExpiryTime, _actionsBuilderInfo[_actionsBuilder].isQueued);
  }

  /// @inheritdoc ISafeEntrypoint
  function getTransactionInfo(uint256 _txId)
    external
    view
    returns (address[] memory _actionsBuilders, bytes memory _actionsData, uint256 _executableAt, bool _isExecuted)
  {
    (_actionsBuilders, _actionsData, _executableAt, _isExecuted) = (
      _transactionInfo[_txId].actionsBuilders,
      _transactionInfo[_txId].actionsData,
      _transactionInfo[_txId].executableAt,
      _transactionInfo[_txId].isExecuted
    );
  }

  /// @inheritdoc ISafeEntrypoint
  function getSafeTransactionHash(uint256 _txId) external view returns (bytes32 _safeTxHash) {
    IActionsBuilder.Action[] memory _actions =
      abi.decode(_transactionInfo[_txId].actionsData, (IActionsBuilder.Action[]));
    bytes memory _multiSendData = _buildMultiSendData(_actions);
    _safeTxHash = _getSafeTransactionHash(_multiSendData, SAFE.nonce());
  }

  /// @inheritdoc ISafeEntrypoint
  function getSafeTransactionHash(uint256 _txId, uint256 _safeNonce) external view returns (bytes32 _safeTxHash) {
    bytes memory _multiSendData =
      _buildMultiSendData(abi.decode(_transactionInfo[_txId].actionsData, (IActionsBuilder.Action[])));
    _safeTxHash = _getSafeTransactionHash(_multiSendData, _safeNonce);
  }

  /// @inheritdoc ISafeEntrypoint
  function getApprovedHashSigners(uint256 _txId) external view returns (address[] memory _approvedHashSigners) {
    _approvedHashSigners = _getApprovedHashSigners(_txId);
  }

  // ~~~ INTERNAL METHODS ~~~

  /**
   * @notice Internal function to execute a transaction
   * @dev Checks if the transaction is executable and builds the necessary data
   * @param _txId The ID of the transaction to execute
   * @param _signers The addresses of the signers to use
   */
  function _executeTransaction(uint256 _txId, address[] memory _signers) internal {
    TransactionInfo storage _txInfo = _transactionInfo[_txId];

    if (_txInfo.executableAt > block.timestamp) revert TransactionNotExecutable();
    if (_txInfo.isExecuted) revert TransactionAlreadyExecuted();

    bytes memory _multiSendData = _buildMultiSendData(abi.decode(_txInfo.actionsData, (IActionsBuilder.Action[])));
    address[] memory _sortedSigners = _sortSigners(_signers);
    bytes memory _signatures = _buildApprovedHashSignatures(_sortedSigners);

    // NOTE: only for event logging
    uint256 _safeNonce = SAFE.nonce();
    bytes32 _safeTxHash = _getSafeTransactionHash(_multiSendData, _safeNonce);
    _execSafeTransaction(_multiSendData, _signatures);

    // Mark the transaction as executed
    _txInfo.isExecuted = true;

    // Unqueue all actions builders
    address[] memory _actionsBuildersToUnqueue = _txInfo.actionsBuilders;
    for (uint256 _i; _i < _actionsBuildersToUnqueue.length; ++_i) {
      _actionsBuilderInfo[_actionsBuildersToUnqueue[_i]].isQueued = false;
    }

    // NOTE: event emitted to log successful execution
    emit TransactionExecuted(_txId, _safeTxHash);
  }

  /**
   * @notice Internal function to execute a Safe transaction
   * @dev Uses the Safe's execTransaction function
   * @param _safeTxData The Safe transaction data
   * @param _signatures The signatures for the transaction
   */
  function _execSafeTransaction(bytes memory _safeTxData, bytes memory _signatures) internal {
    SAFE.execTransaction{value: msg.value}({
      to: MULTI_SEND_CALL_ONLY,
      value: 0,
      data: _safeTxData,
      operation: Enum.Operation.DelegateCall,
      safeTxGas: 0,
      baseGas: 0,
      gasPrice: 0,
      gasToken: address(0),
      refundReceiver: payable(address(this)),
      signatures: _signatures
    });
  }

  // ~~~ INTERNAL VIEW METHODS ~~~

  /**
   * @notice Internal function to fetch actions from an actions builder
   * @dev Uses staticcall to prevent state changes
   * @param _actionsBuilder The address of the actions builder contract
   * @return _actions The batch of actions
   */
  function _fetchActions(address _actionsBuilder) internal view returns (IActionsBuilder.Action[] memory _actions) {
    // Encode the function call for getActions()
    bytes memory _callData = abi.encodeWithSelector(IActionsBuilder.getActions.selector, bytes(''));

    // Make a static call (executes the code but reverts any state changes)
    (bool _success, bytes memory _returnData) = _actionsBuilder.staticcall(_callData);

    // If the call succeeded, decode the returned data
    if (_success && _returnData.length > 0) {
      _actions = abi.decode(_returnData, (IActionsBuilder.Action[]));
    } else {
      revert NotSuccess();
    }
  }

  /**
   * @notice Internal function to collect actions from multiple actions builders
   * @param _actionsBuilders The batch of actions builder contract addresses
   * @return _allActions The combined batch of all actions
   */
  function _collectActions(address[] memory _actionsBuilders)
    internal
    view
    returns (IActionsBuilder.Action[] memory _allActions)
  {
    // Cache for storing actions from each contract
    IActionsBuilder.Action[][] memory _cachedActions = new IActionsBuilder.Action[][](_actionsBuilders.length);
    uint256 _allActionsLength;

    // First pass: call getActions once per contract and cache the results
    for (uint256 _i; _i < _actionsBuilders.length; ++_i) {
      IActionsBuilder.Action[] memory _actions = _fetchActions(_actionsBuilders[_i]);
      _cachedActions[_i] = _actions;
      _allActionsLength += _actions.length;
    }

    // Allocate the final array
    _allActions = new IActionsBuilder.Action[](_allActionsLength);
    uint256 _allActionsIndex;

    // Second pass: fill the final array from cached results
    for (uint256 _i; _i < _cachedActions.length; ++_i) {
      for (uint256 _j; _j < _cachedActions[_i].length; ++_j) {
        _allActions[_allActionsIndex++] = _cachedActions[_i][_j];
      }
    }
  }

  /**
   * @notice Internal function to get the Safe transaction hash
   * @param _safeTxData The Safe transaction data
   * @param _safeNonce The Safe nonce to use for the hash calculation
   * @return _safeTxHash The Safe transaction hash
   */
  function _getSafeTransactionHash(
    bytes memory _safeTxData,
    uint256 _safeNonce
  ) internal view returns (bytes32 _safeTxHash) {
    _safeTxHash = SAFE.getTransactionHash({
      to: MULTI_SEND_CALL_ONLY,
      value: 0,
      data: _safeTxData,
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
   * @notice Internal function to get the list of approved hash signers for a transaction
   * @param _txId The ID of the transaction
   * @return _approvedHashSigners The array of approved hash signer addresses
   */
  function _getApprovedHashSigners(uint256 _txId) internal view returns (address[] memory _approvedHashSigners) {
    address[] memory _safeOwners = SAFE.getOwners();
    uint256 _safeOwnersCount = _safeOwners.length;

    bytes memory _multiSendData =
      _buildMultiSendData(abi.decode(_transactionInfo[_txId].actionsData, (IActionsBuilder.Action[])));
    bytes32 _safeTxHash = _getSafeTransactionHash(_multiSendData, SAFE.nonce());

    // Create a temporary array to store approved hash signers
    address[] memory _tempSigners = new address[](_safeOwnersCount);
    uint256 _approvedHashSignersCount;

    // Single pass through all owners
    for (uint256 _i; _i < _safeOwnersCount; ++_i) {
      // Check if this owner has approved the hash
      if (SAFE.approvedHashes(_safeOwners[_i], _safeTxHash) == 1) {
        _tempSigners[_approvedHashSignersCount] = _safeOwners[_i];
        ++_approvedHashSignersCount;
      }
    }

    // Create the final result array with the exact size needed
    _approvedHashSigners = new address[](_approvedHashSignersCount);

    // Copy from temporary array to final array
    for (uint256 _i; _i < _approvedHashSignersCount; ++_i) {
      _approvedHashSigners[_i] = _tempSigners[_i];
    }
  }

  // ~~~ INTERNAL PURE METHODS ~~~

  /**
   * @notice Internal function to build MultiSend data from actions
   * @dev Encodes each action into the MultiSend format
   * @param _actions The batch of actions to encode
   * @return _multiSendData The encoded MultiSend data
   */
  function _buildMultiSendData(IActionsBuilder.Action[] memory _actions)
    internal
    pure
    returns (bytes memory _multiSendData)
  {
    // Initialize an empty bytes array to avoid null reference
    _multiSendData = new bytes(0);

    // Loop through each action and encode it
    for (uint256 _i; _i < _actions.length; ++_i) {
      // Extract the current action
      IActionsBuilder.Action memory _action = _actions[_i];

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
   * @notice Internal function to build signatures for approved hashes
   * @dev Creates a special signature format using the signer's address
   * @param _signers The array of signer addresses
   * @return _approvedHashSignatures The encoded approved hash signatures
   */
  function _buildApprovedHashSignatures(address[] memory _signers)
    internal
    pure
    returns (bytes memory _approvedHashSignatures)
  {
    // Each signature requires exactly 65 bytes:
    // r: 32 bytes
    // s: 32 bytes
    // v: 1 byte

    // The total length will be signers.length * 65 bytes
    _approvedHashSignatures = new bytes(_signers.length * 65);

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
        mstore(add(add(_approvedHashSignatures, 32), _pos), _r)

        // s value: next 32 bytes of the signature
        mstore(add(add(_approvedHashSignatures, 32), add(_pos, 32)), _s)

        // v value: final 1 byte of the signature
        mstore8(add(add(_approvedHashSignatures, 32), add(_pos, 64)), _v)
      }
    }
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
}
