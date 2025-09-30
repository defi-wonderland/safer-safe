// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from 'forge-std/Test.sol';
import {SetEmergencyTriggerAction} from 'src/contracts/actions-builders/SetEmergencyTriggerAction.sol';
import {IEmergencyModeHook} from 'src/interfaces/IEmergencyModeHook.sol';
import {IActionsBuilder} from 'src/interfaces/actions-builders/IActionsBuilder.sol';

contract UnitSetEmergencyTriggerAction is Test {
  SetEmergencyTriggerAction public setEmergencyTriggerAction;
  address public emergencyTrigger = makeAddr('emergencyTrigger');

  function setUp() external {
    setEmergencyTriggerAction = new SetEmergencyTriggerAction(address(0), emergencyTrigger);
  }

  function test_ConstructorWhenCalled() external view {
    // it sets the emergency trigger address
    assertEq(setEmergencyTriggerAction.EMERGENCY_TRIGGER(), emergencyTrigger);
  }

  function test_GetActionsWhenCalled() external view {
    // it returns an action to set the emergency trigger
    IActionsBuilder.Action[] memory actions = setEmergencyTriggerAction.getActions();
    assertEq(actions[0].target, address(this));
    assertEq(actions[0].data, abi.encodeCall(IEmergencyModeHook.setEmergencyTrigger, (emergencyTrigger)));
    assertEq(actions[0].value, 0);
  }
}
