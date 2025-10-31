// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from 'forge-std/Test.sol';
import {PreApproveAction} from 'src/contracts/actions-builders/PreApproveAction.sol';
import {ICanonGuard} from 'src/interfaces/ICanonGuard.sol';
import {IActionsBuilder} from 'src/interfaces/actions-builders/IActionsBuilder.sol';

contract UnitPreApproveAction is Test {
  uint256 public constant APPROVAL_DURATION = 100;
  PreApproveAction public preApproveAction;
  address public actionsBuilder = makeAddr('actionsBuilder');

  function setUp() external {
    preApproveAction = new PreApproveAction(actionsBuilder, APPROVAL_DURATION);
  }

  function test_Constructor_WhenCalled() external view {
    // it sets the actions builder address
    assertEq(preApproveAction.ACTIONS_BUILDER(), actionsBuilder);
    // it sets the approval duration
    assertEq(preApproveAction.APPROVAL_DURATION(), APPROVAL_DURATION);
  }

  function test_GetActions_WhenCalled() external view {
    // it returns an action to approve the actions builder or action hub
    IActionsBuilder.Action[] memory actions = preApproveAction.getActions();
    assertEq(actions[0].target, address(this));
    assertEq(
      actions[0].data, abi.encodeCall(ICanonGuard.approveActionsBuilderOrHub, (actionsBuilder, APPROVAL_DURATION))
    );
    assertEq(actions[0].value, 0);
  }
}
