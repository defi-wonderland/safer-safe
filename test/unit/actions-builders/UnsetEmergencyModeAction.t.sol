// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from 'forge-std/Test.sol';
import {UnsetEmergencyModeAction} from 'src/contracts/actions-builders/UnsetEmergencyModeAction.sol';
import {IEmergencyModeHook} from 'src/interfaces/IEmergencyModeHook.sol';
import {IActionsBuilder} from 'src/interfaces/actions-builders/IActionsBuilder.sol';

contract UnitUnsetEmergencyModeAction is Test {
  UnsetEmergencyModeAction public unsetEmergencyModeAction;
  address public canonGuard = makeAddr('canonGuard');

  function setUp() external {
    unsetEmergencyModeAction = new UnsetEmergencyModeAction(address(0), canonGuard);
  }

  function test_ConstructorWhenCalled() external view {
    // it sets the canon guard address
    assertEq(unsetEmergencyModeAction.CANON_GUARD(), canonGuard);
  }

  function test_GetActionsWhenCalled() external view {
    // it returns an action to unset the emergency mode
    IActionsBuilder.Action[] memory actions = unsetEmergencyModeAction.getActions();
    assertEq(actions[0].target, canonGuard);
    assertEq(actions[0].data, abi.encodeCall(IEmergencyModeHook.unsetEmergencyMode, ()));
    assertEq(actions[0].value, 0);
  }
}
