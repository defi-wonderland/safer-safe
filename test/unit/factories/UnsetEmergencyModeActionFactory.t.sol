// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {UnsetEmergencyModeActionFactory} from 'contracts/factories/UnsetEmergencyModeActionFactory.sol';
import {Test} from 'forge-std/Test.sol';
import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';
import {IUnsetEmergencyModeAction} from 'interfaces/actions-builders/IUnsetEmergencyModeAction.sol';

contract UnitUnsetEmergencyModeActionFactorycreateUnsetEmergencyModeAction is Test {
  UnsetEmergencyModeActionFactory public unsetEmergencyModeActionFactory;
  IUnsetEmergencyModeAction public auxUnsetEmergencyModeAction;

  function setUp() external {
    unsetEmergencyModeActionFactory = new UnsetEmergencyModeActionFactory();
  }

  function test_WhenCalled(address _canonGuard) external {
    address _unsetEmergencyModeAction = unsetEmergencyModeActionFactory.createUnsetEmergencyModeAction(_canonGuard);

    auxUnsetEmergencyModeAction = IUnsetEmergencyModeAction(
      deployCode('UnsetEmergencyModeAction', abi.encode(address(unsetEmergencyModeActionFactory), _canonGuard))
    );

    // it should deploy an UnsetEmergencyModeAction contract with correct args
    assertEq(address(auxUnsetEmergencyModeAction).code, _unsetEmergencyModeAction.code);

    // it should match the parameters sent to the constructor
    assertEq(IUnsetEmergencyModeAction(_unsetEmergencyModeAction).CANON_GUARD(), _canonGuard);

    // it should set the parent address in the child contract
    assertEq(IActionsBuilder(_unsetEmergencyModeAction).PARENT(), address(unsetEmergencyModeActionFactory));

    // it should store the contract as a factory children
    assertTrue(unsetEmergencyModeActionFactory.isChild(_unsetEmergencyModeAction));
  }
}
