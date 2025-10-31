// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {PreApproveActionFactory} from 'contracts/factories/PreApproveActionFactory.sol';
import {Test} from 'forge-std/Test.sol';
import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';
import {IPreApproveAction} from 'interfaces/actions-builders/IPreApproveAction.sol';
import {IPreApproveActionFactory} from 'interfaces/factories/IPreApproveActionFactory.sol';
import {Utils} from 'test/unit/utils/Utils.sol';

contract UnitPreApproveActionFactorycreatePreApproveAction is Test, Utils {
  PreApproveActionFactory public preApproveActionFactory;
  IPreApproveAction public auxApproveAction;

  function setUp() external {
    preApproveActionFactory = new PreApproveActionFactory();
  }

  function test_WhenCalled(address _actionsBuilder, uint256 _approvalDuration) external {
    // it should emit PreApproveActionCreated event with correct parameters
    vm.expectEmit();
    emit IPreApproveActionFactory.PreApproveActionCreated(
      _getNextContractDeployedAddress(address(preApproveActionFactory)), _actionsBuilder, _approvalDuration
    );

    address _preApproveAction = preApproveActionFactory.createPreApproveAction(_actionsBuilder, _approvalDuration);

    vm.prank(address(preApproveActionFactory));
    auxApproveAction = IPreApproveAction(deployCode('PreApproveAction', abi.encode(_actionsBuilder, _approvalDuration)));

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
