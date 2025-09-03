// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import {UnsetEmergencyModeActionFactory} from 'contracts/factories/UnsetEmergencyModeActionFactory.sol';
import {Test} from 'forge-std/Test.sol';
import {IUnsetEmergencyModeAction} from 'interfaces/actions-builders/IUnsetEmergencyModeAction.sol';

contract UnitUnsetEmergencyModeActionFactorycreateUnsetEmergencyModeAction is Test {
  UnsetEmergencyModeActionFactory public unsetEmergencyModeActionFactory;
  IUnsetEmergencyModeAction public auxUnsetEmergencyModeAction;

  function setUp() external {
    unsetEmergencyModeActionFactory = new UnsetEmergencyModeActionFactory();
  }

  function test_WhenCalled(address _safeEntrypoint) external {
    address _unsetEmergencyModeAction = unsetEmergencyModeActionFactory.createUnsetEmergencyModeAction(_safeEntrypoint);

    auxUnsetEmergencyModeAction =
      IUnsetEmergencyModeAction(deployCode('UnsetEmergencyModeAction', abi.encode(_safeEntrypoint)));

    // it should deploy an UnsetEmergencyModeAction contract with correct args
    assertEq(address(auxUnsetEmergencyModeAction).code, _unsetEmergencyModeAction.code);

    // it should match the parameters sent to the constructor
    assertEq(IUnsetEmergencyModeAction(_unsetEmergencyModeAction).SAFE_ENTRYPOINT(), _safeEntrypoint);
  }
}
