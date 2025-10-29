// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {BaseHandlers, CanonGuard, CanonGuardFactory, Safe} from './handlers/BaseHandlers.sol';

import {HandlersAllowanceClaimor} from './handlers/HandlersAllowanceClaimor.t.sol';
import {HandlersCappedTokenTransfersHub} from './handlers/HandlersCappedTokenTransfersHub.t.sol';
import {HandlersEverclearTokenConversion} from './handlers/HandlersEverclearTokenConversion.t.sol';
import {HandlersOPxAction} from './handlers/HandlersOPxAction.t.sol';

import {HandlersCanonGuard} from './handlers/HandlersCanonGuard.t.sol';
import {HandlersSimpleActions} from './handlers/HandlersSimpleActions.t.sol';
import {HandlersSimpleTransfers} from './handlers/HandlersSimpleTransfers.t.sol';

contract HandlersTarget is
  HandlersCanonGuard,
  HandlersSimpleActions,
  HandlersAllowanceClaimor,
  HandlersCappedTokenTransfersHub,
  HandlersEverclearTokenConversion,
  HandlersOPxAction,
  HandlersSimpleTransfers
{
  constructor(
    CanonGuard __canonGuard,
    CanonGuardFactory __canonGuardFactory,
    Safe __safe,
    address[] memory __signers
  ) BaseHandlers(__canonGuard, __canonGuardFactory, __safe, __signers) {}

  function getCreatedHubs() public view returns (address[] memory) {
    return createdHubs;
  }

  function getCreatedHubsLength() public view returns (uint256) {
    return createdHubs.length;
  }
}
