// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {CanonGuard} from 'contracts/CanonGuard.sol';
import {Factory} from 'contracts/factories/Factory.sol';
import {ICreateX} from 'interfaces/external/ICreateX.sol';
import {ICanonGuardFactory} from 'interfaces/factories/ICanonGuardFactory.sol';

/**
 * @title CanonGuardFactory
 * @notice Contract that deploys CanonGuard contracts
 */
contract CanonGuardFactory is ICanonGuardFactory, Factory {
  // ~~~ STORAGE ~~~

  /// @inheritdoc ICanonGuardFactory
  ICreateX public constant CREATE_X = ICreateX(0xba5Ed099633D3B313e4D5F7bdc1305d3c28ba5Ed);

  // ~~~ FACTORY METHODS ~~~

  /// @inheritdoc ICanonGuardFactory
  function createCanonGuard(
    address _safe,
    uint256 _nonce,
    address _multiSendCallOnly,
    uint256 _shortTxExecutionDelay,
    uint256 _longTxExecutionDelay,
    uint256 _txExpiryDelay,
    uint256 _maxApprovalDuration,
    address _emergencyTrigger,
    address _emergencyCaller
  ) external returns (address _canonGuard) {
    if (_safe != msg.sender) revert DeployerMustBeTheSafe();
    if (_multiSendCallOnly == address(0)) revert MultiSendCallOnlyCannotBeZero();

    // Deploying using hash of the SAFE address as salt
    _canonGuard = CREATE_X.deployCreate3(
      keccak256(abi.encode(_safe, _nonce)),
      abi.encodePacked(
        type(CanonGuard).creationCode,
        abi.encode(
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
      )
    );

    _children[_canonGuard] = true;

    emit CanonGuardCreated(_canonGuard, _safe, _emergencyTrigger, _emergencyCaller);
  }
}
