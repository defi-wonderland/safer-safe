// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from 'forge-std/Test.sol';
import {SetEmergencyCallerAction} from 'src/contracts/actions-builders/SetEmergencyCallerAction.sol';
import {IEmergencyModeHook} from 'src/interfaces/IEmergencyModeHook.sol';
import {IActionsBuilder} from 'src/interfaces/actions-builders/IActionsBuilder.sol';

contract UnitSetEmergencyCallerAction is Test {
  SetEmergencyCallerAction public setEmergencyCallerAction;
  address public canonGuard = makeAddr('canonGuard');
  address public emergencyCaller = makeAddr('emergencyCaller');

  function setUp() external {
    setEmergencyCallerAction = new SetEmergencyCallerAction(address(0), canonGuard, emergencyCaller);
  }

  function test_ConstructorWhenCalled() external view {
    // it sets the canon guard address
    assertEq(setEmergencyCallerAction.CANON_GUARD(), canonGuard);
    // it sets the emergency trigger address
    assertEq(setEmergencyCallerAction.EMERGENCY_CALLER(), emergencyCaller);
  }

  function test_GetActionsWhenCalled() external view {
    // it returns an action to set the emergency caller
    IActionsBuilder.Action[] memory actions = setEmergencyCallerAction.getActions();
    assertEq(actions[0].target, canonGuard);
    assertEq(actions[0].data, abi.encodeCall(IEmergencyModeHook.setEmergencyCaller, (emergencyCaller)));
    assertEq(actions[0].value, 0);
  }
}
