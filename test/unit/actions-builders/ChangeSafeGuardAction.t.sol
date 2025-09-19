// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IGuardManager} from '@safe-smart-account/interfaces/IGuardManager.sol';
import {Test} from 'forge-std/Test.sol';
import {ChangeSafeGuardAction} from 'src/contracts/actions-builders/ChangeSafeGuardAction.sol';
import {ICanonGuard} from 'src/interfaces/ICanonGuard.sol';
import {IActionsBuilder} from 'src/interfaces/actions-builders/IActionsBuilder.sol';

contract UnitChangeSafeGuardAction is Test {
  ChangeSafeGuardAction public changeSafeGuardAction;
  address public safeGuard = makeAddr('safeGuard');

  function setUp() external {
    changeSafeGuardAction = new ChangeSafeGuardAction(address(0), safeGuard);
  }

  function test_ConstructorWhenCalled() external view {
    // it sets the safe guard address
    assertEq(changeSafeGuardAction.SAFE_GUARD(), safeGuard);
  }

  function test_GetActionsWhenCalled() external view {
    // it returns an action to disapprove the actions builder or action hub
    IActionsBuilder.Action[] memory actions = changeSafeGuardAction.getActions();
    assertEq(actions[0].target, address(ICanonGuard(msg.sender).SAFE()));
    assertEq(actions[0].data, abi.encodeCall(IGuardManager.setGuard, (safeGuard)));
    assertEq(actions[0].value, 0);
  }
}
