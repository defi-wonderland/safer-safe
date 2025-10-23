// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ChangeSafeGuardActionFactory} from 'contracts/factories/ChangeSafeGuardActionFactory.sol';
import {Test} from 'forge-std/Test.sol';
import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';
import {IChangeSafeGuardAction} from 'interfaces/actions-builders/IChangeSafeGuardAction.sol';
import {IChangeSafeGuardActionFactory} from 'interfaces/factories/IChangeSafeGuardActionFactory.sol';
import {Utils} from 'test/unit/utils/Utils.sol';

contract UnitChangeSafeGuardActionFactorycreateChangeSafeGuardAction is Test, Utils {
  ChangeSafeGuardActionFactory public changeSafeGuardActionFactory;
  IChangeSafeGuardAction public auxChangeSafeGuardAction;

  function setUp() external {
    changeSafeGuardActionFactory = new ChangeSafeGuardActionFactory();
  }

  function test_WhenCalled(address _safe, address _safeGuard) external {
    vm.assume(_safe != address(0));
    vm.assume(_safeGuard != address(0));

    // it should emit ChangeSafeGuardActionCreated event with correct parameters
    vm.expectEmit();
    emit IChangeSafeGuardActionFactory.ChangeSafeGuardActionCreated(
      _getNextContractDeployedAddress(address(changeSafeGuardActionFactory)), _safeGuard, address(this)
    );

    address _changeSafeGuardActionContract = changeSafeGuardActionFactory.createChangeSafeGuardAction(_safeGuard);

    auxChangeSafeGuardAction = IChangeSafeGuardAction(
      deployCode('ChangeSafeGuardAction', abi.encode(address(changeSafeGuardActionFactory), _safeGuard))
    );

    // it should deploy a ChangeSafeGuardAction contract
    assertEq(address(auxChangeSafeGuardAction).code, _changeSafeGuardActionContract.code);

    // it should match the parameters sent to the constructor
    IChangeSafeGuardAction _changeSafeGuardAction = IChangeSafeGuardAction(_changeSafeGuardActionContract);
    assertEq(_changeSafeGuardAction.SAFE_GUARD(), _safeGuard);

    // it should set the parent address in the child contract
    assertEq(IActionsBuilder(_changeSafeGuardActionContract).PARENT(), address(changeSafeGuardActionFactory));

    // it should store the contract as a factory children
    assertTrue(changeSafeGuardActionFactory.isChild(_changeSafeGuardActionContract));
  }
}
