// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import {ChangeSafeGuardActionFactory} from 'contracts/factories/ChangeSafeGuardActionFactory.sol';
import {Test} from 'forge-std/Test.sol';
import {IChangeSafeGuardAction} from 'interfaces/actions-builders/IChangeSafeGuardAction.sol';

contract UnitChangeSafeGuardActionFactorycreateChangeSafeGuardAction is Test {
  ChangeSafeGuardActionFactory public changeSafeGuardActionFactory;
  IChangeSafeGuardAction public auxChangeSafeGuardAction;

  function setUp() external {
    changeSafeGuardActionFactory = new ChangeSafeGuardActionFactory();
  }

  function test_WhenCalled(address _safe, address _safeGuard) external {
    vm.assume(_safe != address(0));
    vm.assume(_safeGuard != address(0));

    address _changeSafeGuardActionContract = changeSafeGuardActionFactory.createChangeSafeGuardAction(_safe, _safeGuard);

    auxChangeSafeGuardAction =
      IChangeSafeGuardAction(deployCode('ChangeSafeGuardAction', abi.encode(_safe, _safeGuard)));

    // it should deploy a ChangeSafeGuardAction contract
    assertEq(address(auxChangeSafeGuardAction).code, _changeSafeGuardActionContract.code);

    // it should match the parameters sent to the constructor
    IChangeSafeGuardAction _changeSafeGuardAction = IChangeSafeGuardAction(_changeSafeGuardActionContract);
    assertEq(_changeSafeGuardAction.SAFE(), _safe);
    assertEq(_changeSafeGuardAction.SAFE_GUARD(), _safeGuard);
  }
}
