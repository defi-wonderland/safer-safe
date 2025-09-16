// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from 'forge-std/Test.sol';
import {ApproveAction} from 'src/contracts/actions-builders/ApproveAction.sol';
import {ICanonGuard} from 'src/interfaces/ICanonGuard.sol';
import {IActionsBuilder} from 'src/interfaces/actions-builders/IActionsBuilder.sol';

contract UnitApproveAction is Test {
  uint256 public constant APPROVAL_DURATION = 100;
  ApproveAction public approveAction;
  address public canonGuard = makeAddr('canonGuard');
  address public actionsBuilder = makeAddr('actionsBuilder');

  function setUp() external {
    approveAction = new ApproveAction(address(0), canonGuard, actionsBuilder, APPROVAL_DURATION);
  }

  function test_ConstructorWhenCalled() external view {
    // it sets the canon guard address
    assertEq(approveAction.CANON_GUARD(), canonGuard);
    // it sets the actions builder address
    assertEq(approveAction.ACTIONS_BUILDER(), actionsBuilder);
    // it sets the approval duration
    assertEq(approveAction.APPROVAL_DURATION(), APPROVAL_DURATION);
  }

  function test_GetActionsWhenCalled() external view {
    // it returns an action to approve the actions builder or action hub
    IActionsBuilder.Action[] memory actions = approveAction.getActions();
    assertEq(actions[0].target, canonGuard);
    assertEq(
      actions[0].data, abi.encodeCall(ICanonGuard.approveActionsBuilderOrHub, (actionsBuilder, APPROVAL_DURATION))
    );
    assertEq(actions[0].value, 0);
  }
}
