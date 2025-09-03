// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import {SetEmergencyTriggerActionFactory} from 'contracts/factories/SetEmergencyTriggerActionFactory.sol';
import {Test} from 'forge-std/Test.sol';
import {ISetEmergencyTriggerAction} from 'interfaces/actions-builders/ISetEmergencyTriggerAction.sol';

contract UnitSetEmergencyTriggerActionFactorycreateSetEmergencyTriggerAction is Test {
  SetEmergencyTriggerActionFactory public setEmergencyTriggerActionFactory;
  ISetEmergencyTriggerAction public auxSetEmergencyTriggerAction;

  function setUp() external {
    setEmergencyTriggerActionFactory = new SetEmergencyTriggerActionFactory();
  }

  function test_WhenCalled(address _safeEntrypoint, address _emergencyTrigger) external {
    address _setEmergencyTriggerAction =
      setEmergencyTriggerActionFactory.createSetEmergencyTriggerAction(_safeEntrypoint, _emergencyTrigger);

    auxSetEmergencyTriggerAction = ISetEmergencyTriggerAction(
      deployCode('SetEmergencyTriggerAction', abi.encode(_safeEntrypoint, _emergencyTrigger))
    );

    // it should deploy a SetEmergencyTriggerAction contract with correct args
    assertEq(address(auxSetEmergencyTriggerAction).code, _setEmergencyTriggerAction.code);

    // it should match the parameters sent to the constructor
    assertEq(ISetEmergencyTriggerAction(_setEmergencyTriggerAction).SAFE_ENTRYPOINT(), _safeEntrypoint);
    assertEq(ISetEmergencyTriggerAction(_setEmergencyTriggerAction).EMERGENCY_TRIGGER(), _emergencyTrigger);
  }
}
