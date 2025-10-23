// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {SetEmergencyCallerActionFactory} from 'contracts/factories/SetEmergencyCallerActionFactory.sol';
import {Test} from 'forge-std/Test.sol';
import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';
import {ISetEmergencyCallerAction} from 'interfaces/actions-builders/ISetEmergencyCallerAction.sol';
import {ISetEmergencyCallerActionFactory} from 'interfaces/factories/ISetEmergencyCallerActionFactory.sol';
import {Utils} from 'test/unit/utils/Utils.sol';

contract UnitSetEmergencyCallerActionFactorycreateSetEmergencyCallerAction is Test, Utils {
  SetEmergencyCallerActionFactory public setEmergencyCallerActionFactory;
  ISetEmergencyCallerAction public auxSetEmergencyCallerAction;

  function setUp() external {
    setEmergencyCallerActionFactory = new SetEmergencyCallerActionFactory();
  }

  function test_WhenCalled(address _emergencyCaller) external {
    // It should emit SetEmergencyCallerActionCreated event with correct parameters
    vm.expectEmit();
    emit ISetEmergencyCallerActionFactory.SetEmergencyCallerActionCreated(
      _getNextContractDeployedAddress(address(setEmergencyCallerActionFactory)), _emergencyCaller, address(this)
    );

    address _setEmergencyCallerAction = setEmergencyCallerActionFactory.createSetEmergencyCallerAction(_emergencyCaller);

    auxSetEmergencyCallerAction = ISetEmergencyCallerAction(
      deployCode('SetEmergencyCallerAction', abi.encode(address(setEmergencyCallerActionFactory), _emergencyCaller))
    );

    // it should deploy a SetEmergencyCallerAction contract with correct args
    assertEq(address(auxSetEmergencyCallerAction).code, _setEmergencyCallerAction.code);

    // it should match the parameters sent to the constructor
    assertEq(ISetEmergencyCallerAction(_setEmergencyCallerAction).EMERGENCY_CALLER(), _emergencyCaller);

    // it should set the parent address in the child contract
    assertEq(IActionsBuilder(_setEmergencyCallerAction).PARENT(), address(setEmergencyCallerActionFactory));

    // it should store the contract as a factory children
    assertTrue(setEmergencyCallerActionFactory.isChild(_setEmergencyCallerAction));
  }
}
