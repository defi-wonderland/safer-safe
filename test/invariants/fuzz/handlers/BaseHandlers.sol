// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {HandlerHelpers} from './HandlerHelpers.sol';

import {AllowanceClaimorFactory} from 'contracts/factories/AllowanceClaimorFactory.sol';
import {CappedTokenTransfersHubFactory} from 'contracts/factories/CappedTokenTransfersHubFactory.sol';
import {EverclearTokenConversionFactory} from 'contracts/factories/EverclearTokenConversionFactory.sol';
import {OPxActionFactory} from 'contracts/factories/OPxActionFactory.sol';
import {PreApproveActionFactory} from 'contracts/factories/PreApproveActionFactory.sol';
import {SimpleActionsFactory} from 'contracts/factories/SimpleActionsFactory.sol';
import {SimpleTransfersFactory} from 'contracts/factories/SimpleTransfersFactory.sol';

import {ActionTarget} from '../utils/ActionTarget.sol';

import {Safe} from '@safe-smart-account/Safe.sol';
import {CanonGuard} from 'contracts/CanonGuard.sol';
import {CanonGuardFactory} from 'contracts/factories/CanonGuardFactory.sol';

/// @title BaseHandlers
/// @notice Base contract for all handlers providing shared infrastructure
/// @dev Inherits from HandlerHelpers which provides GhostState and common patterns
abstract contract BaseHandlers is HandlerHelpers {
  /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
  //////////////////////////////////////////////////////////////*/

  CanonGuardFactory public canonGuardFactory;

  // All Actions builders factories
  AllowanceClaimorFactory public allowanceClaimorFactory;
  PreApproveActionFactory public preApproveActionFactory;
  CappedTokenTransfersHubFactory public cappedTokenTransfersHubFactory;
  EverclearTokenConversionFactory public everclearTokenConversionFactory;
  OPxActionFactory public opxActionFactory;
  SimpleActionsFactory public simpleActionsFactory;
  SimpleTransfersFactory public simpleTransfersFactory;

  address public currentSigner;
  ActionTarget public actionTarget;

  // Mock data for testing
  address immutable TOKEN_SENDER;
  address immutable TOKEN_RECIPIENT;
  uint256 immutable AMOUNT;

  /*//////////////////////////////////////////////////////////////
                            CONSTANTS
  //////////////////////////////////////////////////////////////*/

  // Fuzzing bounds
  uint256 internal constant MIN_APPROVAL_DURATION = 1;
  uint256 internal constant MAX_APPROVAL_DURATION = 10_000;
  uint256 internal constant MIN_AMOUNT = 1;
  uint256 internal constant MAX_AMOUNT = 1_000_000;
  uint256 internal constant MIN_CAP_MULTIPLIER = 1;
  uint256 internal constant MAX_CAP_MULTIPLIER = 5;
  uint256 internal constant MIN_LOCK_TIME = 1 days;
  uint256 internal constant MAX_LOCK_TIME = 365 days;
  uint256 internal constant MAX_WARP_TIME = 365 days;

  /*//////////////////////////////////////////////////////////////
                            MODIFIERS
  //////////////////////////////////////////////////////////////*/

  /// @notice Select a signer from the signers array based on a seed
  /// @param _seed Random seed for signer selection
  modifier usingSigner(uint256 _seed) {
    currentSigner = _getRandomSigner(_seed);
    _;
  }

  /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
  //////////////////////////////////////////////////////////////*/

  constructor(CanonGuard __canonGuard, CanonGuardFactory __canonGuardFactory, Safe __safe, address[] memory __signers) {
    canonGuard = __canonGuard;
    canonGuardFactory = __canonGuardFactory;
    safe = __safe;
    signers = __signers;
    actionTarget = new ActionTarget();

    allowanceClaimorFactory = new AllowanceClaimorFactory();
    preApproveActionFactory = new PreApproveActionFactory();
    cappedTokenTransfersHubFactory = new CappedTokenTransfersHubFactory();
    everclearTokenConversionFactory = new EverclearTokenConversionFactory();
    opxActionFactory = new OPxActionFactory();
    simpleActionsFactory = new SimpleActionsFactory();
    simpleTransfersFactory = new SimpleTransfersFactory();

    TOKEN_SENDER = makeAddr('TOKEN_SENDER');
    TOKEN_RECIPIENT = makeAddr('TOKEN_RECIPIENT');
    AMOUNT = 100;
  }

  /*//////////////////////////////////////////////////////////////
                            UNIFIED BUILDER HELPERS
  //////////////////////////////////////////////////////////////*/

  /// @notice Unified helper to create, approve, and queue an action builder
  /// @dev Reduces duplication across all action builder handlers
  /// @param _builder The action builder address
  /// @param _type The type of action builder
  /// @param _approvalDuration Duration of approval (will be bounded)
  /// @return success Whether the operation succeeded
  function _createApproveAndQueueBuilder(
    address _builder,
    ActionsBuilderType _type,
    uint256 _approvalDuration
  ) internal returns (bool success) {
    _approvalDuration = bound(_approvalDuration, MIN_APPROVAL_DURATION, MAX_APPROVAL_DURATION);

    // Try to approve the builder
    if (!_tryApproveBuilder(_builder, _approvalDuration)) {
      return false;
    }

    // Queue the builder
    _queueBuilder(_builder, _type, signers[0]);
    return true;
  }

  /*//////////////////////////////////////////////////////////////
                            TIME MANIPULATION
  //////////////////////////////////////////////////////////////*/

  /// @notice Warp time forward to test time-dependent behavior
  /// @dev Allows warping up to MAX_WARP_TIME to test epoch boundaries
  /// @param _timestamp The amount of time to warp forward
  function handler_warp(uint256 _timestamp) public {
    _timestamp = bound(_timestamp, 1, MAX_WARP_TIME);
    vm.warp(block.timestamp + _timestamp);
  }
}
