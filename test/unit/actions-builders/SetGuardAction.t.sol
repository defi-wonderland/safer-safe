// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IGuardManager} from '@safe-smart-account/interfaces/IGuardManager.sol';
import {Test} from 'forge-std/Test.sol';
import {ISafeManageable} from 'interfaces/ISafeManageable.sol';
import {SetGuardAction} from 'src/contracts/actions-builders/SetGuardAction.sol';
import {IActionsBuilder} from 'src/interfaces/actions-builders/IActionsBuilder.sol';

contract UnitSetGuardAction is Test {
  SetGuardAction public setGuardAction;
  address public mockCanonGuard = makeAddr('canonGuard');
  address public mockSafe = makeAddr('safe');

  function setUp() external {
    setGuardAction = new SetGuardAction();
  }

  function test_ConstructorWhenCalled() external view {
    // it sets the parent to address(0)
    assertEq(setGuardAction.PARENT(), address(0));
  }

  function test_GetActionsWhenCalled() external {
    // Mock the canon guard to return the safe address
    vm.mockCall(mockCanonGuard, abi.encodeCall(ISafeManageable.SAFE, ()), abi.encode(mockSafe));

    // Call getActions from the mock canon guard context
    vm.prank(mockCanonGuard);
    IActionsBuilder.Action[] memory actions = setGuardAction.getActions();

    // it returns an action to set the guard to the caller
    assertEq(actions.length, 1);
    assertEq(actions[0].target, mockSafe);
    assertEq(actions[0].data, abi.encodeCall(IGuardManager.setGuard, (mockCanonGuard)));
    assertEq(actions[0].value, 0);
  }
}
