// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {SafeManageable} from 'contracts/SafeManageable.sol';

import {ISafeEntrypoint} from 'interfaces/ISafeEntrypoint.sol';
import {ITransactionBuilder} from 'interfaces/actions/ITransactionBuilder.sol';

import {Enum} from '@safe-smart-account/libraries/Enum.sol';
import {MultiSendCallOnly} from '@safe-smart-account/libraries/MultiSendCallOnly.sol';

/**
 * @title SafeEntrypoint
 * @notice Contract that allows for the execution of transactions on a Safe
 */
contract SafeEntrypoint is SafeManageable, ISafeEntrypoint {
  /// @inheritdoc ISafeEntrypoint
  address public immutable MULTI_SEND_CALL_ONLY;

  /// @inheritdoc ISafeEntrypoint
  mapping(address _txBuilder => bool _isApproved) public approvedTransactionBuilders;

  /// @inheritdoc ISafeEntrypoint
  mapping(bytes32 _txHash => uint256 _txExecutableAt) public txExecutableAt;
  /// @inheritdoc ISafeEntrypoint
  mapping(bytes32 _txHash => bytes _txData) public txData;
  /// @inheritdoc ISafeEntrypoint
  mapping(bytes32 _txHash => bool _isExecuted) public executedTxs;

  /// @notice Global nonce to ensure unique hashes for identical transactions
  uint256 internal _txNonce;

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
  function approveTransactionBuilder(address _txBuilder) external isSafe {
    approvedTransactionBuilders[_txBuilder] = true;
  }

  /// @inheritdoc ISafeEntrypoint
  function disapproveTransactionBuilder(address _txBuilder) external isSafeOwner {
    approvedTransactionBuilders[_txBuilder] = false;
  }

  // ~~~ ACTIONS METHODS ~~~

  /// @inheritdoc ISafeEntrypoint
  function queueTransaction(address _txBuilder) external isSafeOwner returns (bytes32 _txHash) {
    if (!approvedTransactionBuilders[_txBuilder]) revert TransactionBuilderNotApproved();

    ITransactionBuilder.Action[] memory _actions = ITransactionBuilder(_txBuilder).getActions();
    _txHash = keccak256(abi.encode(_actions, _txNonce++));

    uint256 _executableAt = block.timestamp + 1 hours;
    txExecutableAt[_txHash] = _executableAt;
    txData[_txHash] = abi.encode(_actions);

    // NOTE: event picked up by off-chain monitoring service
    emit TransactionQueued(_txHash, _executableAt, false);
  }

  /// @inheritdoc ISafeEntrypoint
  function queueTransaction(ITransactionBuilder.Action[] memory _actions)
    external
    isSafeOwner
    returns (bytes32 _txHash)
  {
    // Validate that the actions array is not empty
    if (_actions.length == 0) {
      revert EmptyActionsArray();
    }

    // Use the existing transaction storage mechanism
    _txHash = keccak256(abi.encode(_actions, _txNonce++));
    uint256 _executableAt = block.timestamp + 7 days;
    txExecutableAt[_txHash] = _executableAt;
    txData[_txHash] = abi.encode(_actions);

    // NOTE: event picked up by off-chain monitoring service
    emit TransactionQueued(_txHash, _executableAt, true);
  }

  /// @inheritdoc ISafeEntrypoint
  function executeTransaction(bytes32 _txHash) external payable {
    _executeTransaction(_txHash, _getApprovedHashSigners(_txHash));
  }

  /// @inheritdoc ISafeEntrypoint
  function executeTransaction(bytes32 _txHash, address[] memory _signers) external payable {
    _executeTransaction(_txHash, _signers);
  }

  /// @inheritdoc ISafeEntrypoint
  function unqueueTransaction(bytes32 _txHash) external isSafeOwner {
    // Check if the transaction exists
    if (txExecutableAt[_txHash] == 0) revert TransactionNotQueued();

    // Check if the transaction has already been executed
    if (executedTxs[_txHash]) revert TransactionAlreadyExecuted();

    // Clear the transaction data
    delete txExecutableAt[_txHash];
    delete txData[_txHash];

    // Emit event for off-chain monitoring
    emit TransactionUnqueued(_txHash);
  }

  // ~~~ VIEW METHODS ~~~

  /// @inheritdoc ISafeEntrypoint
  function getTransactionHash(address _txBuilder, uint256 _txNonce) external view returns (bytes32 _txHash) {
    ITransactionBuilder.Action[] memory _actions = _fetchActions(_txBuilder);
    _txHash = keccak256(abi.encode(_actions, _txNonce));
  }

  /// @inheritdoc ISafeEntrypoint
  function getSafeTransactionHash(address _txBuilder) external view returns (bytes32 _safeTxHash) {
    ITransactionBuilder.Action[] memory _actions = _fetchActions(_txBuilder);
    bytes memory _multiSendData = _buildMultiSendData(_actions);
    _safeTxHash = _getSafeTransactionHash(_multiSendData, SAFE.nonce());
  }

  /// @inheritdoc ISafeEntrypoint
  function getSafeTransactionHash(address _txBuilder, uint256 _safeNonce) external view returns (bytes32 _safeTxHash) {
    ITransactionBuilder.Action[] memory _actions = _fetchActions(_txBuilder);
    bytes memory _multiSendData = _buildMultiSendData(_actions);
    _safeTxHash = _getSafeTransactionHash(_multiSendData, _safeNonce);
  }

  /// @inheritdoc ISafeEntrypoint
  function getSafeTransactionHash(bytes32 _txHash) external view returns (bytes32 _safeTxHash) {
    ITransactionBuilder.Action[] memory _actions = abi.decode(txData[_txHash], (ITransactionBuilder.Action[]));
    bytes memory _multiSendData = _buildMultiSendData(_actions);
    _safeTxHash = _getSafeTransactionHash(_multiSendData, SAFE.nonce());
  }

  /// @inheritdoc ISafeEntrypoint
  function getSafeTransactionHash(bytes32 _txHash, uint256 _safeNonce) external view returns (bytes32 _safeTxHash) {
    bytes memory _multiSendData = _buildMultiSendData(abi.decode(txData[_txHash], (ITransactionBuilder.Action[])));
    _safeTxHash = _getSafeTransactionHash(_multiSendData, _safeNonce);
  }

  /// @inheritdoc ISafeEntrypoint
  function getApprovedHashSigners(bytes32 _txHash) external view returns (address[] memory _approvedHashSigners) {
    _approvedHashSigners = _getApprovedHashSigners(_txHash);
  }

  // ~~~ INTERNAL METHODS ~~~

  /**
   * @notice Internal function to execute a transaction
   * @dev Checks if the transaction is executable and builds the necessary data
   * @param _txHash The hash of the transaction to execute
   * @param _signers The addresses of the signers to use
   */
  function _executeTransaction(bytes32 _txHash, address[] memory _signers) internal {
    if (txExecutableAt[_txHash] > block.timestamp) revert TransactionNotExecutable();
    if (executedTxs[_txHash]) revert TransactionAlreadyExecuted();

    bytes memory _multiSendData = _buildMultiSendData(abi.decode(txData[_txHash], (ITransactionBuilder.Action[])));
    address[] memory _sortedSigners = _sortSigners(_signers);
    bytes memory _signatures = _buildApprovedHashSignatures(_sortedSigners);

    // NOTE: only for event logging
    uint256 _safeNonce = SAFE.nonce();
    bytes32 _safeTxHash = _getSafeTransactionHash(_multiSendData, _safeNonce);
    _execSafeTransaction(_multiSendData, _signatures);

    // Mark the transaction as executed
    executedTxs[_txHash] = true;

    // NOTE: event emitted to log successful execution
    emit TransactionExecuted(_txHash, _safeTxHash);
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

  /**
   * @notice Internal function to fetch actions from a contract
   * @dev Uses staticcall to prevent state changes
   * @param _txBuilder The address of the transaction builder contract
   * @return _actions The array of actions
   */
  function _fetchActions(address _txBuilder) internal view returns (ITransactionBuilder.Action[] memory _actions) {
    // Encode the function call for getActions()
    bytes memory _callData = abi.encodeWithSelector(ITransactionBuilder.getActions.selector, bytes(''));

    // Make a static call (executes the code but reverts any state changes)
    (bool _success, bytes memory _returnData) = _txBuilder.staticcall(_callData);

    // If the call succeeded, decode the returned data
    if (_success && _returnData.length > 0) {
      _actions = abi.decode(_returnData, (ITransactionBuilder.Action[]));
    } else {
      revert NotSuccess();
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
   * @param _txHash The hash of the transaction
   * @return _approvedHashSigners The array of approved hash signer addresses
   */
  function _getApprovedHashSigners(bytes32 _txHash) internal view returns (address[] memory _approvedHashSigners) {
    address[] memory _safeOwners = SAFE.getOwners();
    uint256 _safeOwnersCount = _safeOwners.length;

    bytes memory _multiSendData = _buildMultiSendData(abi.decode(txData[_txHash], (ITransactionBuilder.Action[])));
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

  /**
   * @notice Internal function to build MultiSend data from actions array
   * @dev Encodes each action into the MultiSend format
   * @param _actions The array of actions to encode
   * @return _multiSendData The encoded MultiSend data
   */
  function _buildMultiSendData(ITransactionBuilder.Action[] memory _actions)
    internal
    pure
    returns (bytes memory _multiSendData)
  {
    // Initialize an empty bytes array to avoid null reference
    _multiSendData = new bytes(0);

    // Loop through each action and encode it
    for (uint256 _i; _i < _actions.length; ++_i) {
      // Extract the current action
      ITransactionBuilder.Action memory _action = _actions[_i];

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
