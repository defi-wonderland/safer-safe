// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from 'forge-std/Test.sol';
import {ISimpleActions} from 'interfaces/actions-builders/ISimpleActions.sol';

import {AllowanceClaimorFactory} from 'contracts/factories/AllowanceClaimorFactory.sol';
import {ApproveActionFactory} from 'contracts/factories/ApproveActionFactory.sol';
import {CappedTokenTransfersHubFactory} from 'contracts/factories/CappedTokenTransfersHubFactory.sol';
import {EverclearTokenConversionFactory} from 'contracts/factories/EverclearTokenConversionFactory.sol';
import {EverclearTokenStakeFactory} from 'contracts/factories/EverclearTokenStakeFactory.sol';
import {OPxActionFactory} from 'contracts/factories/OPxActionFactory.sol';
import {SimpleActionsFactory} from 'contracts/factories/SimpleActionsFactory.sol';
import {SimpleTransfersFactory} from 'contracts/factories/SimpleTransfersFactory.sol';

import {ActionTarget} from '../utils/ActionTarget.sol';

import {Safe} from '@safe-smart-account/Safe.sol';
import {CanonGuard} from 'contracts/CanonGuard.sol';
import {CanonGuardFactory} from 'contracts/factories/CanonGuardFactory.sol';

/// @notice Base contract for all handlers, include ghost storage and constructor
abstract contract BaseHandlers is Test {
  CanonGuard public canonGuard;
  CanonGuardFactory public canonGuardFactory;
  Safe public safe;

  // All Actions builders factories
  AllowanceClaimorFactory public allowanceClaimorFactory;
  ApproveActionFactory public approveActionFactory;
  CappedTokenTransfersHubFactory public cappedTokenTransfersHubFactory;
  EverclearTokenConversionFactory public everclearTokenConversionFactory;
  EverclearTokenStakeFactory public everclearTokenStakeFactory;
  OPxActionFactory public opxActionFactory;
  SimpleActionsFactory public simpleActionsFactory;
  SimpleTransfersFactory public simpleTransfersFactory;

  // Ghost storage
  enum ActionsBuilderType {
    ALLOWANCE_CLAIMOR,
    CAPPED_TOKEN_TRANSFERS_HUB,
    EVERCLEAR_TOKEN_CONVERSION,
    EVERCLEAR_TOKEN_STAKE,
    OPX_ACTION,
    SIMPLE_ACTIONS,
    SIMPLE_TRANSFERS
  }

  mapping(bytes32 => address) public ghost_hashToActionsBuilder;
  bytes32[] public ghost_hashes;
  mapping(bytes32 => uint256) public ghost_timestampOfActionQueued;
  mapping(address => bool) public ghost_approvedActionsBuilder;
  mapping(address => ActionsBuilderType) public ghost_actionsBuilderType;
  address[] public signers;
  address public currentSigner;

  ActionTarget public actionTarget;

  // Mock data
  address immutable TOKEN_SENDER;
  address immutable TOKEN_RECIPIENT;
  uint256 immutable AMOUNT;

  modifier usingSigner(uint256 _seed) {
    currentSigner = signers[_seed % signers.length];
    _;
  }

  constructor(CanonGuard __canonGuard, CanonGuardFactory __canonGuardFactory, Safe __safe, address[] memory __signers) {
    canonGuard = __canonGuard;
    canonGuardFactory = __canonGuardFactory;
    safe = __safe;
    signers = __signers;
    actionTarget = new ActionTarget();

    allowanceClaimorFactory = new AllowanceClaimorFactory();
    approveActionFactory = new ApproveActionFactory();
    cappedTokenTransfersHubFactory = new CappedTokenTransfersHubFactory();
    everclearTokenConversionFactory = new EverclearTokenConversionFactory();
    everclearTokenStakeFactory = new EverclearTokenStakeFactory();
    opxActionFactory = new OPxActionFactory();
    simpleActionsFactory = new SimpleActionsFactory();
    simpleTransfersFactory = new SimpleTransfersFactory();

    TOKEN_SENDER = makeAddr('TOKEN_SENDER');
    TOKEN_RECIPIENT = makeAddr('TOKEN_RECIPIENT');
    AMOUNT = 100;
  }

  function handler_warp(uint256 _timestamp) public {
    _timestamp = bound(_timestamp, 1, canonGuard.LONG_TX_EXECUTION_DELAY() * 10);
    vm.warp(block.timestamp + _timestamp);
  }
}
