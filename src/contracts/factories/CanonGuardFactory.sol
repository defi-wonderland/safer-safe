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
  // ~~~ STORAGE ~~~

  /// @inheritdoc ICanonGuardFactory
  address public immutable MULTI_SEND_CALL_ONLY;

  // ~~~ CONSTRUCTOR ~~~

  /**
   * @notice Constructor that sets up the MultiSendCallOnly contract
   * @param _multiSendCallOnly The MultiSendCallOnly contract address
   */
  constructor(address _multiSendCallOnly) {
    if (_multiSendCallOnly == address(0)) revert MultiSendCallOnlyCannotBeZero();

    MULTI_SEND_CALL_ONLY = _multiSendCallOnly;
  }

  // ~~~ FACTORY METHODS ~~~

  /// @inheritdoc ICanonGuardFactory
  function createCanonGuard(
    address _safe,
    uint256 _shortTxExecutionDelay,
    uint256 _longTxExecutionDelay,
    uint256 _txExpiryDelay,
    uint256 _maxApprovalDuration,
    address _emergencyTrigger,
    address _emergencyCaller
  ) external returns (address _canonGuard) {
    _canonGuard = address(
      new CanonGuard(
        address(this),
        _safe,
        MULTI_SEND_CALL_ONLY,
        _shortTxExecutionDelay,
        _longTxExecutionDelay,
        _txExpiryDelay,
        _maxApprovalDuration,
        _emergencyTrigger,
        _emergencyCaller
      )
    );

    _children[_canonGuard] = true;
  }
}
