// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IGuardManager} from '@safe-smart-account/interfaces/IGuardManager.sol';
import {Test} from 'forge-std/Test.sol';
import {ChangeSafeGuardAction} from 'src/contracts/actions-builders/ChangeSafeGuardAction.sol';

import {ISafeManageable} from 'src/interfaces/ISafeManageable.sol';
import {IActionsBuilder} from 'src/interfaces/actions-builders/IActionsBuilder.sol';

contract UnitChangeSafeGuardAction is Test {
  ChangeSafeGuardAction public changeSafeGuardAction;
  address public mockSafe = makeAddr('safe');
  address public mockCanonGuard = makeAddr('canonGuard');

  function setUp() external {
    changeSafeGuardAction = new ChangeSafeGuardAction(address(0), mockCanonGuard);
  }

  function test_Constructor_WhenCalled() external view {
    // it sets the safe guard address
    assertEq(changeSafeGuardAction.SAFE_GUARD(), mockCanonGuard);
  }

  function test_GetActions_WhenCalled() external {
    vm.mockCall(mockCanonGuard, abi.encodeWithSelector(ISafeManageable.SAFE.selector), abi.encode(mockSafe));
    vm.expectCall(mockCanonGuard, abi.encodeWithSelector(ISafeManageable.SAFE.selector));

    // it returns an action to change the safe guard
    vm.prank(mockCanonGuard);
    IActionsBuilder.Action[] memory actions = changeSafeGuardAction.getActions();
    assertEq(actions.length, 1);
    assertEq(actions[0].target, mockSafe);
    assertEq(actions[0].data, abi.encodeCall(IGuardManager.setGuard, (mockCanonGuard)));
    assertEq(actions[0].value, 0);
  }
}
