// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IERC20} from 'forge-std/interfaces/IERC20.sol';

import {Safe} from 'safe-contracts/contracts/Safe.sol';
import {BaseGuard} from 'safe-contracts/contracts/base/GuardManager.sol';
import {Enum} from 'safe-contracts/contracts/common/Enum.sol';
import 'safe-contracts/contracts/common/Enum.sol';

contract AllowListTimelockGuard is BaseGuard {
  struct Action {
    address target;
    bytes data;
    uint256 value;
  }

  struct TransactionData {
    bytes32 txHash;
    uint256 executableAt;
  }

  uint256 public constant SHORT_DELAY = 1 hours;
  uint256 public constant LONG_DELAY = 7 days;

  Safe public immutable safe;

  address public immutable emergencyMsig;

  mapping(uint256 => Action) public queuedTransaction;
  mapping(uint256 => TransactionData) public transactionDataOf;

  mapping(bytes32 => bool) public allowList;

  modifier onlySafe() {
    if (msg.sender != address(safe)) revert OnlySafe();
    _;
  }

  modifier onlySigner() {
    if (!safe.isOwner(msg.sender)) revert OnlySigner();
    _;
  }

  modifier onlyEmergencyMsig() {
    if (msg.sender != emergencyMsig) revert OnlyEmergencyMsig();
    _;
  }

  error OnlySafe();
  error OnlySigner();
  error OnlyEmergencyMsig();
  error ActiveTimeLock();

  constructor(Safe _safe, address _emergencyMsig) {
    safe = _safe;
    emergencyMsig = _emergencyMsig;
  }

  /// @notice Called by Safe before tx execution
  /// @custom:overriding BaseGuard
  function checkTransaction(
    address to,
    uint256 value,
    bytes memory data,
    Enum.Operation operation,
    uint256 safeTxGas,
    uint256 baseGas,
    uint256 gasPrice,
    address gasToken,
    address payable refundReceiver,
    bytes memory signatures,
    address msgSender
  ) external override {
    if (!hasMatured(to, data)) revert ActiveTimeLock();
  }

  /// @notice Called by Safe after executing the call
  /// @custom:overriding BaseGuard
  function checkAfterExecution(bytes32 txHash, bool success) external override {}

  /// @notice Queue a transaction to be executed after the timelock
  function queueTransaction(Action memory action) public onlySigner {
    uint256 _delayBeforeExecution = isInAllowList(action) ? SHORT_DELAY : LONG_DELAY;

    uint256 _currentNonce = safe.nonce();

    bytes32 txHash = safe.getTransactionHash({
      to: action.target,
      value: action.value,
      data: action.data,
      operation: Enum.Operation.Call,
      safeTxGas: 0,
      baseGas: 0,
      gasPrice: 0,
      gasToken: address(0),
      refundReceiver: payable(address(this)),
      _nonce: _currentNonce
    });

    TransactionData memory _transactionData =
      TransactionData({txHash: txHash, executableAt: block.timestamp + _delayBeforeExecution});

    queuedTransaction[_currentNonce] = action;
    transactionDataOf[_currentNonce] = _transactionData;
  }

  /// @notice Add an address and/or function selector to the allow list
  function addToAllowList() public onlySafe {}

  /// @notice Remove an address and/or function selector from the allow list
  function removeFromAllowList() public onlySafe {}

  /// @notice Deactivate the guard (by emergency msig)
  function deactivateGuard() public onlyEmergencyMsig {}

  /// @notice Bypass the guard for a specific transaction (by emergency msig)
  function bypassGuardForTransaction() public onlyEmergencyMsig {}

  /// @notice Execute queued transactions
  function executeQueuedTransactions(uint256[] calldata _nonces) public {}

  function isInAllowList(Action memory action) public view returns (bool) {
    bytes32 _target = (bytes32(uint256(uint160(action.target))) << 96) | bytes4(action.data);
    // We check if address-selector pair is allowed
    bool _allowed = allowList[_target];
    // if not, we check if the address is allowed/selector wild carded (ie 0)
    if (!_allowed) {
      _allowed = allowList[bytes32(uint256(uint160(action.target)))];
    }

    return _allowed;
  }

  function hasMatured(address to, bytes memory data) public view returns (bool) {}
}
