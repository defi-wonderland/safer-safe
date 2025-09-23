// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from 'forge-std/Test.sol';
import {DisapproveAction} from 'src/contracts/actions-builders/DisapproveAction.sol';
import {ICanonGuard} from 'src/interfaces/ICanonGuard.sol';
import {IActionsBuilder} from 'src/interfaces/actions-builders/IActionsBuilder.sol';

contract UnitDisapproveAction is Test {
  DisapproveAction public disapproveAction;
  address public actionsBuilder = makeAddr('actionsBuilder');

  function setUp() external {
    disapproveAction = new DisapproveAction(address(0), actionsBuilder);
  }

  function test_ConstructorWhenCalled() external view {
    // it sets the actions builder address
    assertEq(disapproveAction.ACTIONS_BUILDER(), actionsBuilder);
  }

  function test_GetActionsWhenCalled() external view {
    // it returns an action to disapprove the actions builder or action hub
    IActionsBuilder.Action[] memory actions = disapproveAction.getActions();
    assertEq(actions[0].target, address(this));
    assertEq(actions[0].data, abi.encodeCall(ICanonGuard.approveActionsBuilderOrHub, (actionsBuilder, 0)));
    assertEq(actions[0].value, 0);
  }
}
