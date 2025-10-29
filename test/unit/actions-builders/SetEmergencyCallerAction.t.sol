// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from 'forge-std/Test.sol';
import {SetEmergencyCallerAction} from 'src/contracts/actions-builders/SetEmergencyCallerAction.sol';
import {IEmergencyModeHook} from 'src/interfaces/IEmergencyModeHook.sol';
import {IActionsBuilder} from 'src/interfaces/actions-builders/IActionsBuilder.sol';

contract UnitSetEmergencyCallerAction is Test {
  SetEmergencyCallerAction public setEmergencyCallerAction;
  address public emergencyCaller = makeAddr('emergencyCaller');

  function setUp() external {
    setEmergencyCallerAction = new SetEmergencyCallerAction(emergencyCaller);
  }

  function test_Constructor_WhenCalled() external view {
    // it sets the emergency trigger address
    assertEq(setEmergencyCallerAction.EMERGENCY_CALLER(), emergencyCaller);
  }

  function test_GetActions_WhenCalled() external view {
    // it returns an action to set the emergency caller
    IActionsBuilder.Action[] memory actions = setEmergencyCallerAction.getActions();
    assertEq(actions[0].target, address(this));
    assertEq(actions[0].data, abi.encodeCall(IEmergencyModeHook.setEmergencyCaller, (emergencyCaller)));
    assertEq(actions[0].value, 0);
  }
}
