// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ApproveActionFactory} from 'contracts/factories/ApproveActionFactory.sol';
import {Test} from 'forge-std/Test.sol';
import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';
import {IApproveAction} from 'interfaces/actions-builders/IApproveAction.sol';

contract UnitApproveActionFactorycreateApproveAction is Test {
  ApproveActionFactory public approveActionFactory;
  IApproveAction public auxApproveAction;

  function setUp() external {
    approveActionFactory = new ApproveActionFactory();
  }

  function test_WhenCalled(address _canonGuard, address _actionsBuilder, uint256 _approvalDuration) external {
    address _approveAction = approveActionFactory.createApproveAction(_canonGuard, _actionsBuilder, _approvalDuration);

    auxApproveAction = IApproveAction(
      deployCode(
        'ApproveAction', abi.encode(address(approveActionFactory), _canonGuard, _actionsBuilder, _approvalDuration)
      )
    );

    // it should deploy an ApproveAction contract with correct args
    assertEq(address(auxApproveAction).code, _approveAction.code);

    // it should match the parameters sent to the constructor
    assertEq(IApproveAction(_approveAction).CANON_GUARD(), _canonGuard);
    assertEq(IApproveAction(_approveAction).ACTIONS_BUILDER(), _actionsBuilder);
    assertEq(IApproveAction(_approveAction).APPROVAL_DURATION(), _approvalDuration);

    // it should set the parent address in the child contract
    assertEq(IActionsBuilder(_approveAction).PARENT(), address(approveActionFactory));

    // it should store the contract as a factory children
    assertTrue(approveActionFactory.isChild(_approveAction));
  }
}
