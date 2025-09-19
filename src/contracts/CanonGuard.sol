// SPDX-License-Identifier: MIT

/*

Made with ♥ by

░██╗░░░░░░░██╗░█████╗░███╗░░██╗██████╗░███████╗██████╗░██╗░░░░░░█████╗░███╗░░██╗██████╗░
░██║░░██╗░░██║██╔══██╗████╗░██║██╔══██╗██╔════╝██╔══██╗██║░░░░░██╔══██╗████╗░██║██╔══██╗
░╚██╗████╗██╔╝██║░░██║██╔██╗██║██║░░██║█████╗░░██████╔╝██║░░░░░███████║██╔██╗██║██║░░██║
░░████╔═████║░██║░░██║██║╚████║██║░░██║██╔══╝░░██╔══██╗██║░░░░░██╔══██║██║╚████║██║░░██║
░░╚██╔╝░╚██╔╝░╚█████╔╝██║░╚███║██████╔╝███████╗██║░░██║███████╗██║░░██║██║░╚███║██████╔╝
░░░╚═╝░░░╚═╝░░░╚════╝░╚═╝░░╚══╝╚═════╝░╚══════╝╚═╝░░╚═╝╚══════╝╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░

https://wonderland.xyz

*/

pragma solidity 0.8.30;

import {Enum} from '@safe-smart-account/libraries/Enum.sol';
import {MultiSendCallOnly} from '@safe-smart-account/libraries/MultiSendCallOnly.sol';
import {EmergencyModeHook} from 'contracts/EmergencyModeHook.sol';
import {OnlyCanonGuard} from 'contracts/OnlyCanonGuard.sol';
import {SafeManageable} from 'contracts/SafeManageable.sol';
import {ICanonGuard} from 'interfaces/ICanonGuard.sol';
import {IActionHub} from 'interfaces/action-hubs/IActionHub.sol';
import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';
import {EnumerableSetLib} from 'solady/utils/EnumerableSetLib.sol';

/**
 * @title CanonGuard
 * @notice Contract that allows for the execution of transactions on a Safe
 */
contract CanonGuard is OnlyCanonGuard, EmergencyModeHook, ICanonGuard {
  using EnumerableSetLib for EnumerableSetLib.AddressSet;

  // ~~~ STORAGE ~~~
  /// @inheritdoc ICanonGuard
  uint256 public constant MIN_EXPIRY_TIME = 1 hours;

  /// @inheritdoc ICanonGuard
  address public immutable PARENT;

  /// @inheritdoc ICanonGuard
  address public immutable MULTI_SEND_CALL_ONLY;

  /// @inheritdoc ICanonGuard
  uint256 public immutable SHORT_TX_EXECUTION_DELAY;

  /// @inheritdoc ICanonGuard
  uint256 public immutable LONG_TX_EXECUTION_DELAY;

  /// @inheritdoc ICanonGuard
  uint256 public immutable TX_EXPIRY_DELAY;

  /// @inheritdoc ICanonGuard
  uint256 public immutable MAX_APPROVAL_DURATION;

  /// @inheritdoc ICanonGuard
  mapping(address _actionsBuilder => uint256 _approvalExpiresAt) public approvalExpiries;

  /// @inheritdoc ICanonGuard
  mapping(address _actionsBuilder => TransactionInfo _txInfo) public transactionsInfo;

  /// @notice Whether the contract is in simulation mode. This can be used in simulation tools like Tenderly
  /// to bypass the signature threshold check while executing transactions.
  bool internal _isSimulation;

  /// @notice The action builders queue
  EnumerableSetLib.AddressSet internal __queuedActionBuilders;

  // ~~~ CONSTRUCTOR ~~~

  /**
   * @notice Constructor that sets up the Safe, MultiSendCallOnly, execution delays and default expiry delay
   * @param _parent The parent that deployed the CanonGuard contract
   * @param _safe The Gnosis Safe contract address
   * @param _multiSendCallOnly The MultiSendCallOnly contract address
   * @param _shortTxExecutionDelay The short transaction execution delay (in seconds)
   * @param _longTxExecutionDelay The long transaction execution delay (in seconds)
   * @param _txExpiryDelay The transaction expiry delay (in seconds after executable)
   * @param _maxApprovalDuration The maximum approval duration for an actions builder or hub (in seconds)
   * @param _emergencyTrigger The emergency trigger address
   * @param _emergencyCaller The emergency caller address
   */
  constructor(
    address _parent,
    address _safe,
    address _multiSendCallOnly,
    uint256 _shortTxExecutionDelay,
    uint256 _longTxExecutionDelay,
    uint256 _txExpiryDelay,
    uint256 _maxApprovalDuration,
    address _emergencyTrigger,
    address _emergencyCaller
  ) SafeManageable(_safe) EmergencyModeHook(_emergencyTrigger, _emergencyCaller) {
    if (_txExpiryDelay < MIN_EXPIRY_TIME) revert TxExpiryDelayCannotBeLessThanMin();
    if (_maxApprovalDuration < MIN_EXPIRY_TIME) revert MaxApprovalDurationCannotBeLessThanMin();
    if (_shortTxExecutionDelay > _longTxExecutionDelay) revert ShortDelayCannotBeGreaterThanLongDelay();
    if (_txExpiryDelay > type(uint128).max) revert TxExpiryDelayCannotBeGreaterThanMax();
    if (_longTxExecutionDelay > type(uint128).max) revert LongDelayCannotBeGreaterThanMax();

    PARENT = _parent;
    MULTI_SEND_CALL_ONLY = _multiSendCallOnly;
    SHORT_TX_EXECUTION_DELAY = _shortTxExecutionDelay;
    LONG_TX_EXECUTION_DELAY = _longTxExecutionDelay;
    TX_EXPIRY_DELAY = _txExpiryDelay;
    MAX_APPROVAL_DURATION = _maxApprovalDuration;
  }

  // ~~~ ADMIN METHODS ~~~

  /// @inheritdoc ICanonGuard
  function approveActionsBuilderOrHub(address _actionsBuilderOrHub, uint256 _approvalDuration) external isSafe {
    if (_approvalDuration > MAX_APPROVAL_DURATION) revert InvalidApprovalDuration();

    uint256 _approvalExpiresAt = block.timestamp + _approvalDuration;
    approvalExpiries[_actionsBuilderOrHub] = _approvalExpiresAt;
    emit ActionsBuilderOrHubApproved(_actionsBuilderOrHub, _approvalDuration, _approvalExpiresAt);
  }

  // ~~~ TRANSACTION METHODS ~~~

  /// @inheritdoc ICanonGuard
  function queueHubTransaction(address _actionHub, address _actionsBuilder) external isSafeOwner {
    if (!IActionHub(_actionHub).isChild(_actionsBuilder)) revert InvalidHubOrActionsBuilder();
    bool _actionIsPreApproved = _isPreApproved(_actionHub);
    _queueTransaction(_actionsBuilder, _actionIsPreApproved);

    emit TransactionQueued(_actionHub, msg.sender, _actionsBuilder, _actionIsPreApproved);
  }

  /// @inheritdoc ICanonGuard
  function queueTransaction(address _actionsBuilder) external isSafeOwner {
    // It is expected that IS_BUILDER will revert if it is not an IActionsBuilder
    // If it is an IActionsBuilder then it would always return true so we don't need to check the returned value
    try IActionsBuilder(_actionsBuilder).IS_BUILDER() {}
    catch {
      revert NotAnActionsBuilder();
    }

    bool _actionIsPreApproved = _isPreApproved(_actionsBuilder);
    _queueTransaction(_actionsBuilder, _actionIsPreApproved);

    emit TransactionQueued(address(0), msg.sender, _actionsBuilder, _actionIsPreApproved);
  }

  /// @inheritdoc ICanonGuard
  function executeTransaction(address _actionsBuilder) external payable {
    _onBeforeExecution();

    (bytes32 _safeTxHash, address[] memory _signers, bytes memory _multiSendData) =
      _prepareTransaction(_actionsBuilder, SAFE.nonce());

    _executeTransaction(_actionsBuilder, _safeTxHash, _signers, _multiSendData);
  }

  /// @inheritdoc ICanonGuard
  function executeTransactions(address[] memory _actionsBuilders) external payable {
    _onBeforeExecution();

    uint256 _safeNonce = SAFE.nonce();

    for (uint256 _i; _i < _actionsBuilders.length; ++_i) {
      (bytes32 _safeTxHash, address[] memory _signers, bytes memory _multiSendData) =
        _prepareTransaction(_actionsBuilders[_i], _safeNonce + _i);

      _executeTransaction(_actionsBuilders[_i], _safeTxHash, _signers, _multiSendData);
    }
  }

  /// @inheritdoc ICanonGuard
  function executeNoActionTransaction() external {
    _onBeforeExecution();

    bytes32 _safeTxHash = _getSafeTransactionHash(_buildMultiSendData(new IActionsBuilder.Action[](0)), SAFE.nonce());
    address[] memory _signers = _getApprovedHashSigners(_safeTxHash);
    _sortSigners(_signers);
    bytes memory _signatures = _buildApprovedHashSignatures(_signers);

    _execSafeTransaction(_buildMultiSendData(new IActionsBuilder.Action[](0)), _signatures);

    emit NoActionTransactionExecuted(_safeTxHash, _signers);
  }

  /// @inheritdoc ICanonGuard
  function cancelEnqueuedTransaction(address _actionsBuilder) external {
    TransactionInfo memory _txInfo = transactionsInfo[_actionsBuilder];
    if (_txInfo.expiresAt == 0) revert NoTransactionQueued();
    if (msg.sender != _txInfo.proposer) revert CallerMustBeTransactionProposer();

    IActionsBuilder.Action[] memory _actions = abi.decode(_txInfo.actionsData, (IActionsBuilder.Action[]));

    bytes memory _multiSendData = _buildMultiSendData(_actions);
    bytes32 _safeTxHash = _getSafeTransactionHash(_multiSendData, SAFE.nonce());
    address[] memory _signers = _getApprovedHashSigners(_safeTxHash);

    if (_signers.length > 0) revert TransactionWithSignaturesCannotBeCancelled();

    // Remove the transaction from the queue and mapping
    delete transactionsInfo[_actionsBuilder];
    __queuedActionBuilders.remove(_actionsBuilder);

    emit EnqueuedTransactionCancelled(_actionsBuilder, msg.sender, _safeTxHash);
  }

  // ~~~ GETTER METHODS ~~~

  /// @inheritdoc ICanonGuard
  function getSafeTransactionHash(address _actionsBuilder) external view returns (bytes32 _safeTxHash) {
    _safeTxHash = getSafeTransactionHash(_actionsBuilder, SAFE.nonce());
  }

  /// @inheritdoc ICanonGuard
  function getApprovedHashSigners(
    address _actionsBuilder,
    uint256 _safeNonce
  ) external view returns (address[] memory _approvedHashSigners) {
    bytes32 _safeTxHash;

    if (_actionsBuilder != address(0)) {
      // If the actions builder is not the zero address, we need to get the transaction hash from the queued transactions
      TransactionInfo memory _txInfo = transactionsInfo[_actionsBuilder];
      if (_txInfo.expiresAt == 0) revert NoTransactionQueued();

      IActionsBuilder.Action[] memory _actions = abi.decode(_txInfo.actionsData, (IActionsBuilder.Action[]));

      bytes memory _multiSendData = _buildMultiSendData(_actions);
      _safeTxHash = _getSafeTransactionHash(_multiSendData, _safeNonce);
    } else {
      // If the actions builder is the zero address, it means we want to execute an empty transaction
      _safeTxHash = _getSafeTransactionHash(_buildMultiSendData(new IActionsBuilder.Action[](0)), _safeNonce);
    }

    _approvedHashSigners = _getApprovedHashSigners(_safeTxHash);
  }

  /// @inheritdoc ICanonGuard
  function getSafeNonce() external view returns (uint256 _safeNonce) {
    _safeNonce = SAFE.nonce();
  }

  /// @inheritdoc ICanonGuard
  function getQueuedActionBuilders() external view returns (address[] memory _queuedActionBuilders) {
    _queuedActionBuilders = __queuedActionBuilders.values();
  }

  /// @inheritdoc ICanonGuard
  function getSafeTransactionHash(
    address _actionsBuilder,
    uint256 _safeNonce
  ) public view returns (bytes32 _safeTxHash) {
    TransactionInfo memory _txInfo = transactionsInfo[_actionsBuilder];
    if (_txInfo.expiresAt == 0) revert NoTransactionQueued();

    IActionsBuilder.Action[] memory _actions = abi.decode(_txInfo.actionsData, (IActionsBuilder.Action[]));

    bytes memory _multiSendData = _buildMultiSendData(_actions);
    _safeTxHash = _getSafeTransactionHash(_multiSendData, _safeNonce);
  }

  /// @inheritdoc ICanonGuard
  function getSafeEmptyTransactionHash(uint256 _safeNonce) public view returns (bytes32 _safeTxHash) {
    _safeTxHash = _getSafeTransactionHash(_buildMultiSendData(new IActionsBuilder.Action[](0)), _safeNonce);
  }

  // ~~~ INTERNAL METHODS ~~~

  /**
   * @notice Internal function to execute a transaction
   * @dev Checks if the transaction is executable and builds the necessary data
   * @param _actionsBuilder The actions builder address of the transaction to execute
   * @param _safeTxHash The hash of the Safe transaction
   * @param _signers The addresses of the signers to use
   * @param _multiSendData The encoded MultiSend data
   */
  function _executeTransaction(
    address _actionsBuilder,
    bytes32 _safeTxHash,
    address[] memory _signers,
    bytes memory _multiSendData
  ) internal {
    TransactionInfo memory _txInfo = transactionsInfo[_actionsBuilder];
    if (_txInfo.executableAt > block.timestamp) revert TransactionNotYetExecutable();
    if (_txInfo.expiresAt <= block.timestamp) revert TransactionExpired();

    // Remove the transaction from the queue and mapping
    delete transactionsInfo[_actionsBuilder];
    __queuedActionBuilders.remove(_actionsBuilder);

    // Sort the _signers array
    _sortSigners(_signers);
    bytes memory _signatures = _buildApprovedHashSignatures(_signers);
    _execSafeTransaction(_multiSendData, _signatures);

    // NOTE: event emitted to log successful execution
    emit TransactionExecuted(_actionsBuilder, _safeTxHash, _signers);
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

  /**
   * @notice Internal function to queue a transaction
   * @param _actionsBuilder The actions builder contract address
   * @param _actionIsPreApproved Whether the actions builder is pre-approved
   */
  function _queueTransaction(address _actionsBuilder, bool _actionIsPreApproved) internal {
    // If approved, use short execution delay. Otherwise, use long execution delay
    uint256 _txExecutionDelay = _actionIsPreApproved ? SHORT_TX_EXECUTION_DELAY : LONG_TX_EXECUTION_DELAY;

    // Revert if the transaction is already queued and not expired
    if (!__queuedActionBuilders.add(_actionsBuilder)) {
      TransactionInfo memory _queuedTransactionInfo = transactionsInfo[_actionsBuilder];
      if (_queuedTransactionInfo.expiresAt > block.timestamp) {
        revert TransactionAlreadyQueued(_actionsBuilder);
      }
    }

    // Fetch actions from the builder
    IActionsBuilder.Action[] memory _actions = IActionsBuilder(_actionsBuilder).getActions();

    // Store the transaction information
    transactionsInfo[_actionsBuilder] = TransactionInfo({
      proposer: msg.sender,
      actionsData: abi.encode(_actions),
      executableAt: block.timestamp + _txExecutionDelay,
      expiresAt: block.timestamp + _txExecutionDelay + TX_EXPIRY_DELAY
    });
  }

  // ~~~ INTERNAL VIEW METHODS ~~~

  /**
   * @notice Internal function to prepare a transaction to be executed
   * @dev If isSmulation is enabled, the signers array will be set to this contract address.
   * @param _actionsBuilder The actions builder address of the transaction to prepare
   * @param _safeNonce The Safe nonce to use for the hash calculation. For multiple transactions, the nonce should
   * be incremented by 1 for each transaction.
   * @return _safeTxHash The Safe transaction hash
   * @return _signers The array of signer addresses. The array is not sorted in this function.
   * @return _multiSendData The encoded MultiSend data used to execute the transaction in Safe.
   */
  function _prepareTransaction(
    address _actionsBuilder,
    uint256 _safeNonce
  ) internal view returns (bytes32 _safeTxHash, address[] memory _signers, bytes memory _multiSendData) {
    TransactionInfo memory _txInfo = transactionsInfo[_actionsBuilder];
    if (_txInfo.expiresAt == 0) revert NoTransactionQueued();

    IActionsBuilder.Action[] memory _actions = abi.decode(_txInfo.actionsData, (IActionsBuilder.Action[]));

    _multiSendData = _buildMultiSendData(_actions);
    _safeTxHash = _getSafeTransactionHash(_multiSendData, _safeNonce);
    if (!_isSimulation) {
      _signers = _getApprovedHashSigners(_safeTxHash);
    } else {
      // To run in simulation mode first the CanonGuard needs to be added as an owner and the threshold set to 1
      _signers = new address[](1);
      _signers[0] = address(this);
    }
  }

  /**
   * @notice Internal function to check if the actions builder (or actionHub) is pre-approved
   * @param _actionsBuilderOrActionHub The actions builder contract address (or actionHub)
   * @return _isApproved Whether the actions builder (or actionHub) is pre-approved
   */
  function _isPreApproved(address _actionsBuilderOrActionHub) internal view returns (bool _isApproved) {
    _isApproved = approvalExpiries[_actionsBuilderOrActionHub] > block.timestamp;
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
      // Check if this owner has approved the hash
      if (SAFE.approvedHashes(_safeOwner, _safeTxHash) == 1) {
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
   */
  function _sortSigners(address[] memory _signers) internal pure {
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
  }
}
