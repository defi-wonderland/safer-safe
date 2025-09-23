// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {SetEmergencyTriggerActionFactory} from 'contracts/factories/SetEmergencyTriggerActionFactory.sol';
import {Test} from 'forge-std/Test.sol';

import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';
import {ISetEmergencyTriggerAction} from 'interfaces/actions-builders/ISetEmergencyTriggerAction.sol';

contract UnitSetEmergencyTriggerActionFactorycreateSetEmergencyTriggerAction is Test {
  SetEmergencyTriggerActionFactory public setEmergencyTriggerActionFactory;
  ISetEmergencyTriggerAction public auxSetEmergencyTriggerAction;

  function setUp() external {
    setEmergencyTriggerActionFactory = new SetEmergencyTriggerActionFactory();
  }

  function test_WhenCalled(address _emergencyTrigger) external {
    address _setEmergencyTriggerAction =
      setEmergencyTriggerActionFactory.createSetEmergencyTriggerAction(_emergencyTrigger);

    auxSetEmergencyTriggerAction = ISetEmergencyTriggerAction(
      deployCode('SetEmergencyTriggerAction', abi.encode(address(setEmergencyTriggerActionFactory), _emergencyTrigger))
    );

    // it should deploy a SetEmergencyTriggerAction contract with correct args
    assertEq(address(auxSetEmergencyTriggerAction).code, _setEmergencyTriggerAction.code);

    // it should match the parameters sent to the constructor
    assertEq(ISetEmergencyTriggerAction(_setEmergencyTriggerAction).EMERGENCY_TRIGGER(), _emergencyTrigger);

    // it should set the parent address in the child contract
    assertEq(IActionsBuilder(_setEmergencyTriggerAction).PARENT(), address(setEmergencyTriggerActionFactory));

    // it should store the contract as a factory children
    assertTrue(setEmergencyTriggerActionFactory.isChild(_setEmergencyTriggerAction));
  }
}
