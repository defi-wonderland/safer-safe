// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {CanonGuard} from 'contracts/CanonGuard.sol';
import {Factory} from 'contracts/factories/Factory.sol';
import {ICanonGuardFactory} from 'interfaces/factories/ICanonGuardFactory.sol';

/**
 * @title CanonGuardFactory
 * @notice Contract that deploys CanonGuard contracts
 */
contract CanonGuardFactory is ICanonGuardFactory, Factory {
  // ~~~ FACTORY METHODS ~~~

  /// @inheritdoc ICanonGuardFactory
  function createCanonGuard(
    address _safe,
    address _multiSendCallOnly,
    uint256 _shortTxExecutionDelay,
    uint256 _longTxExecutionDelay,
    uint256 _txExpiryDelay,
    uint256 _maxApprovalDuration,
    address _emergencyTrigger,
    address _emergencyCaller
  ) external returns (address _canonGuard) {
    if (_multiSendCallOnly == address(0)) revert MultiSendCallOnlyCannotBeZero();

    _canonGuard = address(
      new CanonGuard(
        address(this),
        _safe,
        _multiSendCallOnly,
        _shortTxExecutionDelay,
        _longTxExecutionDelay,
        _txExpiryDelay,
        _maxApprovalDuration,
        _emergencyTrigger,
        _emergencyCaller
      )
    );

    _children[_canonGuard] = true;

    emit CanonGuardCreated(_canonGuard, _safe, _emergencyTrigger, _emergencyCaller);
  }
}
