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
  uint256 public immutable SHORT_EXECUTION_DELAY;

  /// @inheritdoc ISafeEntrypoint
  uint256 public immutable LONG_EXECUTION_DELAY;

  /// @inheritdoc ISafeEntrypoint
  uint256 public immutable DEFAULT_TX_EXPIRY_DELAY;

  /// @inheritdoc ISafeEntrypoint
  uint256 public transactionNonce;

  /// @notice Maps an actions builder to its approval expiry time
  mapping(address _actionsBuilder => uint256 _approvalExpiryTime) public approvalExpiries;

  /// @notice Maps a transaction ID to its information
  mapping(uint256 _txId => TransactionInfo _txInfo) public transactions;

  /// @inheritdoc ISafeEntrypoint
  mapping(address _signer => mapping(bytes32 _safeTxHash => bool _isDisapproved)) public disapprovedHashes;

  /**
   * @notice Constructor that sets up the Safe and MultiSendCallOnly contracts
   * @param _safe The Gnosis Safe contract address
   * @param _multiSendCallOnly The MultiSendCallOnly contract address
   * @param _shortExecutionDelay The short execution delay (in seconds)
   * @param _longExecutionDelay The long execution delay (in seconds)
   * @param _defaultTxExpiryDelay The default expiry delay for transactions
   */
  constructor(
    address _safe,
    address _multiSendCallOnly,
    uint256 _shortExecutionDelay,
    uint256 _longExecutionDelay,
    uint256 _defaultTxExpiryDelay
  ) SafeManageable(_safe) {
    MULTI_SEND_CALL_ONLY = _multiSendCallOnly;

    SHORT_EXECUTION_DELAY = _shortExecutionDelay;
    LONG_EXECUTION_DELAY = _longExecutionDelay;
    DEFAULT_TX_EXPIRY_DELAY = _defaultTxExpiryDelay;
  }

  // ~~~ ADMIN METHODS ~~~

  /// @inheritdoc ISafeEntrypoint
  function approveActionsBuilder(address _actionsBuilder, uint256 _approvalDuration) external isSafe {
    uint256 _expiryTime = block.timestamp + _approvalDuration;
    approvalExpiries[_actionsBuilder] = _expiryTime;
    emit ActionsBuilderApproved(_actionsBuilder, _approvalDuration, _expiryTime);
  }

  // ~~~ TRANSACTION METHODS ~~~

  /// @inheritdoc ISafeEntrypoint
  function queueTransaction(address _actionsBuilder, uint256 _expiryDelay) external isSafeOwner returns (uint256 _txId) {
    if (approvalExpiries[_actionsBuilder] <= block.timestamp) {
      revert ActionsBuilderNotApproved();
    }

    // Generate a simple transaction ID
    _txId = ++transactionNonce;

    // Collect actions from the builder
    IActionsBuilder.Action[] memory _actions = _fetchActions(_actionsBuilder);

    // Use default expiry delay if duration is 0
    _expiryDelay = _expiryDelay == 0 ? DEFAULT_TX_EXPIRY_DELAY : _expiryDelay;

    // Store the transaction information
    transactions[_txId] = TransactionInfo({
      actionsBuilder: _actionsBuilder,
      actionsData: abi.encode(_actions),
      executableAt: block.timestamp + SHORT_EXECUTION_DELAY,
      expiresAt: block.timestamp + SHORT_EXECUTION_DELAY + _expiryDelay,
      isExecuted: false
    });

    // NOTE: event picked up by off-chain monitoring service
    emit TransactionQueued(_txId, false);
  }

  /// @inheritdoc ISafeEntrypoint
  function queueTransaction(
    IActionsBuilder.Action calldata _action,
    uint256 _expiryDelay
  ) external isSafeOwner returns (uint256 _txId) {
    // Generate a simple transaction ID
    _txId = ++transactionNonce;

    // Use default expiry delay if duration is 0
    _expiryDelay = _expiryDelay == 0 ? DEFAULT_TX_EXPIRY_DELAY : _expiryDelay;

    // Store the transaction information
    transactions[_txId] = TransactionInfo({
      actionsBuilder: address(0),
      actionsData: abi.encode(_action),
      executableAt: block.timestamp + LONG_EXECUTION_DELAY,
      expiresAt: block.timestamp + LONG_EXECUTION_DELAY + _expiryDelay,
      isExecuted: false
    });

    // NOTE: event picked up by off-chain monitoring service
    emit TransactionQueued(_txId, true);
  }

  /// @inheritdoc ISafeEntrypoint
  function executeTransaction(uint256 _txId) external payable {
    TransactionInfo storage _txInfo = transactions[_txId];
    IActionsBuilder.Action[] memory _actions = abi.decode(_txInfo.actionsData, (IActionsBuilder.Action[]));

    bytes memory _multiSendData = _buildMultiSendData(_actions);
    bytes32 _safeTxHash = _getSafeTransactionHash(_multiSendData, SAFE.nonce());
    address[] memory _signers = _getApprovedHashSigners(_safeTxHash);

    _executeTransaction(_txId, _safeTxHash, _signers, _multiSendData);
  }

  /// @inheritdoc ISafeEntrypoint
  function executeTransaction(uint256 _txId, address[] calldata _signers) external payable {
    TransactionInfo storage _txInfo = transactions[_txId];
    IActionsBuilder.Action[] memory _actions = abi.decode(_txInfo.actionsData, (IActionsBuilder.Action[]));

    bytes memory _multiSendData = _buildMultiSendData(_actions);
    bytes32 _safeTxHash = _getSafeTransactionHash(_multiSendData, SAFE.nonce());

    // Check if any of the provided signers has disapproved the hash or has not approved it
    uint256 _signersLength = _signers.length;
    address _signer;
    for (uint256 _i; _i < _signersLength; ++_i) {
      _signer = _signers[_i];
      if (disapprovedHashes[_signer][_safeTxHash] || SAFE.approvedHashes(_signer, _safeTxHash) != 1) {
        revert InvalidSigner(_safeTxHash, _signer);
      }
    }

    _executeTransaction(_txId, _safeTxHash, _signers, _multiSendData);
  }

  /**
   * @notice Disapproves a Safe transaction hash
   * @dev Can be called by any Safe owner
   * @param _safeTxHash The hash of the Safe transaction to disapprove
   */
  function disapproveSafeTransactionHash(bytes32 _safeTxHash) external isSafeOwner {
    // Check if the hash has been approved in the Safe
    if (SAFE.approvedHashes(msg.sender, _safeTxHash) != 1) {
      revert SafeTransactionHashNotApproved();
    }

    // Mark the hash as disapproved for this signer
    disapprovedHashes[msg.sender][_safeTxHash] = true;

    emit SafeTransactionHashDisapproved(_safeTxHash, msg.sender);
  }

  // ~~~ EXTERNAL VIEW METHODS ~~~

  /// @inheritdoc ISafeEntrypoint
  function getSafeTransactionHash(uint256 _txId) external view returns (bytes32 _safeTxHash) {
    _safeTxHash = getSafeTransactionHash(_txId, SAFE.nonce());
  }

  /// @inheritdoc ISafeEntrypoint
  function getApprovedHashSigners(uint256 _txId) external view returns (address[] memory _approvedHashSigners) {
    _approvedHashSigners = getApprovedHashSigners(_txId, SAFE.nonce());
  }

  /// @inheritdoc ISafeEntrypoint
  function getApprovedHashSigners(bytes32 _safeTxHash) external view returns (address[] memory _approvedHashSigners) {
    _approvedHashSigners = _getApprovedHashSigners(_safeTxHash);
  }

  // ~~~ PUBLIC VIEW METHODS ~~~

  /// @inheritdoc ISafeEntrypoint
  function getSafeTransactionHash(uint256 _txId, uint256 _safeNonce) public view returns (bytes32 _safeTxHash) {
    TransactionInfo storage _txInfo = transactions[_txId];
    IActionsBuilder.Action[] memory _actions = abi.decode(_txInfo.actionsData, (IActionsBuilder.Action[]));

    bytes memory _multiSendData = _buildMultiSendData(_actions);
    _safeTxHash = _getSafeTransactionHash(_multiSendData, _safeNonce);
  }

  /// @inheritdoc ISafeEntrypoint
  function getApprovedHashSigners(
    uint256 _txId,
    uint256 _safeNonce
  ) public view returns (address[] memory _approvedHashSigners) {
    TransactionInfo storage _txInfo = transactions[_txId];
    IActionsBuilder.Action[] memory _actions = abi.decode(_txInfo.actionsData, (IActionsBuilder.Action[]));

    bytes memory _multiSendData = _buildMultiSendData(_actions);
    bytes32 _safeTxHash = _getSafeTransactionHash(_multiSendData, _safeNonce);
    _approvedHashSigners = _getApprovedHashSigners(_safeTxHash);
  }

  // ~~~ INTERNAL METHODS ~~~

  /**
   * @notice Internal function to execute a transaction
   * @dev Checks if the transaction is executable and builds the necessary data
   * @param _txId The ID of the transaction to execute
   * @param _safeTxHash The hash of the Safe transaction
   * @param _signers The addresses of the signers to use
   * @param _multiSendData The encoded MultiSend data
   */
  function _executeTransaction(
    uint256 _txId,
    bytes32 _safeTxHash,
    address[] memory _signers,
    bytes memory _multiSendData
  ) internal {
    TransactionInfo storage _txInfo = transactions[_txId];

    if (_txInfo.executableAt > block.timestamp) revert TransactionNotYetExecutable();
    if (_txInfo.isExecuted) revert TransactionAlreadyExecuted();
    if (_txInfo.expiresAt <= block.timestamp) revert TransactionExpired();

    address[] memory _sortedSigners = _sortSigners(_signers);
    bytes memory _signatures = _buildApprovedHashSignatures(_sortedSigners);

    _execSafeTransaction(_multiSendData, _signatures);

    // Mark the transaction as executed
    _txInfo.isExecuted = true;

    // NOTE: only for event logging
    bool _isArbitrary = _txInfo.actionsBuilder == address(0);

    // NOTE: event emitted to log successful execution
    emit TransactionExecuted(_txId, _isArbitrary, _safeTxHash, _signers);
  }

  /**
   * @notice Internal function to execute a Safe transaction
   * @dev Uses the Safe's execTransaction function
   * @param _multiSendData The encoded MultiSend data
   * @param _signatures The signatures for the transaction
   */
  function _execSafeTransaction(bytes memory _multiSendData, bytes memory _signatures) internal {
    SAFE.execTransaction{value: msg.value}({
      to: MULTI_SEND_CALL_ONLY,
      value: 0, // Value must be 0 for delegatecall operations
      data: _multiSendData,
      operation: Enum.Operation.DelegateCall,
      safeTxGas: 0,
      baseGas: 0,
      gasPrice: 0,
      gasToken: address(0),
      refundReceiver: payable(address(0)),
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
   * @notice Internal function to get the Safe transaction hash
   * @param _multiSendData The encoded MultiSend data
   * @param _safeNonce The Safe nonce to use for the hash calculation
   * @return _safeTxHash The Safe transaction hash
   */
  function _getSafeTransactionHash(
    bytes memory _multiSendData,
    uint256 _safeNonce
  ) internal view returns (bytes32 _safeTxHash) {
    _safeTxHash = SAFE.getTransactionHash({
      to: MULTI_SEND_CALL_ONLY,
      value: 0,
      data: _multiSendData,
      operation: Enum.Operation.DelegateCall,
      safeTxGas: 0,
      baseGas: 0,
      gasPrice: 0,
      gasToken: address(0),
      refundReceiver: payable(address(0)),
      _nonce: _safeNonce
    });
  }

  /**
   * @notice Internal function to get the list of approved hash signers for a transaction
   * @param _safeTxHash The hash of the Safe transaction
   * @return _approvedHashSigners The array of approved hash signer addresses
   */
  function _getApprovedHashSigners(bytes32 _safeTxHash) internal view returns (address[] memory _approvedHashSigners) {
    address[] memory _safeOwners = SAFE.getOwners();
    uint256 _safeOwnersLength = _safeOwners.length;

    // Create a temporary array to store approved hash signers
    address[] memory _tempSigners = new address[](_safeOwnersLength);
    uint256 _approvedHashSignersCount;

    // Single pass through all owners
    address _safeOwner;
    for (uint256 _i; _i < _safeOwnersLength; ++_i) {
      _safeOwner = _safeOwners[_i];
      // Check if this owner has approved the hash and hasn't disapproved it
      if (!disapprovedHashes[_safeOwner][_safeTxHash] && SAFE.approvedHashes(_safeOwner, _safeTxHash) == 1) {
        _tempSigners[_approvedHashSignersCount] = _safeOwner;
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
    uint256 _actionsLength = _actions.length;
    IActionsBuilder.Action memory _action;
    bytes memory _encodedAction;
    for (uint256 _i; _i < _actionsLength; ++_i) {
      // Extract the current action
      _action = _actions[_i];

      // For each action, we encode:
      // 1 byte: operation (0 = Call, 1 = DelegateCall) - using 0 (Call) by default
      // 20 bytes: target address
      // 32 bytes: ether value
      // 32 bytes: data length
      // N bytes: data payload

      // Encode each action using abi.encodePacked to avoid padding
      _encodedAction = abi.encodePacked(
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

    // Set s to zero (not used for approved hash validation)
    bytes32 _s = bytes32(0);

    // Set v to 1 (indicates this is an approved hash signature)
    uint8 _v = 1;

    uint256 _signersLength = _signers.length;
    bytes32 _r;
    bytes memory _signature;
    for (uint256 _i; _i < _signersLength; ++_i) {
      // Set r to the signer address (converted to bytes32)
      _r = bytes32(uint256(uint160(_signers[_i])));

      // 65 bytes per signature
      // r value: first 32 bytes of the signature
      // s value: next 32 bytes of the signature
      // v value: final 1 byte of the signature
      _signature = abi.encodePacked(_r, _s, _v);

      // Write the signature values to the byte array
      _approvedHashSignatures = abi.encodePacked(_approvedHashSignatures, _signature);
    }
  }

  /**
   * @notice Internal function to sort signer addresses
   * @dev Uses bubble sort to sort addresses numerically
   * @param _signers The array of signer addresses to sort
   * @return _sortedSigners The sorted array of signer addresses
   */
  function _sortSigners(address[] memory _signers) internal pure returns (address[] memory _sortedSigners) {
    uint256 _signersLength = _signers.length;
    address _temp;
    for (uint256 _i; _i < _signersLength; ++_i) {
      for (uint256 _j; _j < _signersLength - _i - 1; ++_j) {
        // If the current element is greater than the next element, swap them
        if (_signers[_j] > _signers[_j + 1]) {
          // Swap elements
          _temp = _signers[_j];
          _signers[_j] = _signers[_j + 1];
          _signers[_j + 1] = _temp;
        }
      }
    }

    return _signers;
  }
}
