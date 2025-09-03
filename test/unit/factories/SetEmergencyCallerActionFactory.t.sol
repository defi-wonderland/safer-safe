// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import {SetEmergencyCallerActionFactory} from 'contracts/factories/SetEmergencyCallerActionFactory.sol';
import {Test} from 'forge-std/Test.sol';
import {ISetEmergencyCallerAction} from 'interfaces/actions-builders/ISetEmergencyCallerAction.sol';

contract UnitSetEmergencyCallerActionFactorycreateSetEmergencyCallerAction is Test {
  SetEmergencyCallerActionFactory public setEmergencyCallerActionFactory;
  ISetEmergencyCallerAction public auxSetEmergencyCallerAction;

  function setUp() external {
    setEmergencyCallerActionFactory = new SetEmergencyCallerActionFactory();
  }

  function test_WhenCalled(address _safeEntrypoint, address _emergencyCaller) external {
    address _setEmergencyCallerAction =
      setEmergencyCallerActionFactory.createSetEmergencyCallerAction(_safeEntrypoint, _emergencyCaller);

    auxSetEmergencyCallerAction =
      ISetEmergencyCallerAction(deployCode('SetEmergencyCallerAction', abi.encode(_safeEntrypoint, _emergencyCaller)));

    // it should deploy a SetEmergencyCallerAction contract with correct args
    assertEq(address(auxSetEmergencyCallerAction).code, _setEmergencyCallerAction.code);

    // it should match the parameters sent to the constructor
    assertEq(ISetEmergencyCallerAction(_setEmergencyCallerAction).SAFE_ENTRYPOINT(), _safeEntrypoint);
    assertEq(ISetEmergencyCallerAction(_setEmergencyCallerAction).EMERGENCY_CALLER(), _emergencyCaller);
  }
}
