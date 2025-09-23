// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {CanonGuard, ICanonGuard} from 'contracts/CanonGuard.sol';
import {EnumerableSetLib} from 'solady/utils/EnumerableSetLib.sol';

contract CanonGuardForTest is CanonGuard {
  using EnumerableSetLib for EnumerableSetLib.AddressSet;

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
  )
    CanonGuard(
      _parent,
      _safe,
      _multiSendCallOnly,
      _shortTxExecutionDelay,
      _longTxExecutionDelay,
      _txExpiryDelay,
      _maxApprovalDuration,
      _emergencyTrigger,
      _emergencyCaller
    )
  {}

  // Mock functions to directly manipulate storage
  function mockTransaction(
    address _proposer,
    address _actionsBuilder,
    bytes memory _actionsData,
    uint256 _executableAt,
    uint256 _expiresAt,
    bool _isPreApproved
  ) external {
    __queuedActionBuilders.add(_actionsBuilder);
    transactionsInfo[_actionsBuilder] = ICanonGuard.TransactionInfo({
      proposer: _proposer,
      actionsData: _actionsData,
      executableAt: _executableAt,
      expiresAt: _expiresAt,
      isPreApproved: _isPreApproved
    });
  }

  function mockApprovalExpiry(address _actionsBuilder, uint256 _expiry) external {
    approvalExpiries[_actionsBuilder] = _expiry;
  }
}
