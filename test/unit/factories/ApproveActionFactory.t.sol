// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import {ApproveActionFactory} from 'contracts/factories/ApproveActionFactory.sol';
import {Test} from 'forge-std/Test.sol';
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

    // it should set the factory address in the child contract
    assertEq(IApproveAction(_approveAction).FACTORY(), address(approveActionFactory));

    // it should store the contract in the factory
    assertTrue(approveActionFactory.isChild(_approveAction));
  }
}
