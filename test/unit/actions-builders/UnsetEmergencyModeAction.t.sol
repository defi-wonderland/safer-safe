// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from 'forge-std/Test.sol';
import {UnsetEmergencyModeAction} from 'src/contracts/actions-builders/UnsetEmergencyModeAction.sol';
import {IEmergencyModeHook} from 'src/interfaces/IEmergencyModeHook.sol';
import {IActionsBuilder} from 'src/interfaces/actions-builders/IActionsBuilder.sol';

contract UnitUnsetEmergencyModeActiongetActions is Test {
  UnsetEmergencyModeAction public unsetEmergencyModeAction;

  function setUp() external {
    unsetEmergencyModeAction = new UnsetEmergencyModeAction();
  }

  function test_WhenCalled(address _canonGuard) external {
    // it returns an action to unset the emergency mode
    vm.prank(_canonGuard);
    IActionsBuilder.Action[] memory actions = unsetEmergencyModeAction.getActions();
    assertEq(actions[0].target, _canonGuard);
    assertEq(actions[0].data, abi.encodeCall(IEmergencyModeHook.unsetEmergencyMode, ()));
    assertEq(actions[0].value, 0);
  }
}
