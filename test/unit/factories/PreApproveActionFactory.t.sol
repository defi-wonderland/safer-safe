// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {PreApproveActionFactory} from 'contracts/factories/PreApproveActionFactory.sol';
import {Test} from 'forge-std/Test.sol';
import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';
import {IPreApproveAction} from 'interfaces/actions-builders/IPreApproveAction.sol';

contract UnitPreApproveActionFactorycreateApproveAction is Test {
  PreApproveActionFactory public preApproveActionFactory;
  IPreApproveAction public auxApproveAction;

  function setUp() external {
    preApproveActionFactory = new PreApproveActionFactory();
  }

  function test_WhenCalled(address _actionsBuilder, uint256 _approvalDuration) external {
    address _preApproveAction = preApproveActionFactory.createApproveAction(_actionsBuilder, _approvalDuration);

    auxApproveAction = IPreApproveAction(
      deployCode('PreApproveAction', abi.encode(address(preApproveActionFactory), _actionsBuilder, _approvalDuration))
    );

    // it should deploy an PreApproveAction contract with correct args
    assertEq(address(auxApproveAction).code, _preApproveAction.code);

    // it should match the parameters sent to the constructor
    assertEq(IPreApproveAction(_preApproveAction).ACTIONS_BUILDER(), _actionsBuilder);
    assertEq(IPreApproveAction(_preApproveAction).APPROVAL_DURATION(), _approvalDuration);

    // it should set the parent address in the child contract
    assertEq(IActionsBuilder(_preApproveAction).PARENT(), address(preApproveActionFactory));

    // it should store the contract as a factory children
    assertTrue(preApproveActionFactory.isChild(_preApproveAction));
  }
}
