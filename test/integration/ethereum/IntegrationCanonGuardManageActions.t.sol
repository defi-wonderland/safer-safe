// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ApproveActionFactory} from 'contracts/factories/ApproveActionFactory.sol';
import {DisapproveActionFactory} from 'contracts/factories/DisapproveActionFactory.sol';
import {IApproveAction} from 'interfaces/actions-builders/IApproveAction.sol';
import {IDisapproveAction} from 'interfaces/actions-builders/IDisapproveAction.sol';
import {IApproveActionFactory} from 'interfaces/factories/IApproveActionFactory.sol';
import {IDisapproveActionFactory} from 'interfaces/factories/IDisapproveActionFactory.sol';
import {IntegrationEthereumBase} from 'test/integration/ethereum/IntegrationEthereumBase.sol';

contract IntegrationCanonGuardManageActions is IntegrationEthereumBase {
  IApproveActionFactory public approveActionFactory;
  IApproveAction public approveAction;

  IDisapproveActionFactory public disapproveActionFactory;
  IDisapproveAction public disapproveAction;

  address public actionsBuilder;
  uint256 public constant APPROVAL_DURATION = 7 days;

  function setUp() public override {
    super.setUp();

    actionsBuilder = makeAddr('actionsBuilder');

    // Deploy the ApproveAction contract
    approveActionFactory = new ApproveActionFactory();
    approveAction = IApproveAction(
      approveActionFactory.createApproveAction(address(canonGuard), address(actionsBuilder), APPROVAL_DURATION)
    );

    // Deploy the DisapproveAction contract
    disapproveActionFactory = new DisapproveActionFactory();
    disapproveAction =
      IDisapproveAction(disapproveActionFactory.createDisapproveAction(address(canonGuard), address(actionsBuilder)));
  }

  function test_ApproveActionsBuilder() public {
    // Queue the transaction
    vm.prank(_safeOwners[0]);
    canonGuard.queueTransaction(address(approveAction));

    // Wait for the timelock period
    vm.warp(block.timestamp + LONG_TX_EXECUTION_DELAY);

    // Get the Safe transaction hash
    bytes32 _safeTxHash = canonGuard.getSafeTransactionHash(address(approveAction));

    // Approve the Safe transaction hash
    for (uint256 _i; _i < _safeThreshold; ++_i) {
      vm.startPrank(_safeOwners[_i]);
      SAFE_PROXY.approveHash(_safeTxHash);
    }
    vm.stopPrank();

    // Execute the transaction
    canonGuard.executeTransaction(address(approveAction));

    // Assert if the actions builder is approved
    assertEq(canonGuard.approvalExpiries(address(actionsBuilder)), block.timestamp + APPROVAL_DURATION);
  }

  function test_DisapproveActionsBuilder() public {
    // Queue the transaction
    vm.prank(_safeOwners[0]);
    canonGuard.queueTransaction(address(disapproveAction));

    // Wait for the timelock period
    vm.warp(block.timestamp + LONG_TX_EXECUTION_DELAY);

    // Get the Safe transaction hash
    bytes32 _safeTxHash = canonGuard.getSafeTransactionHash(address(disapproveAction));

    // Approve the Safe transaction hash
    for (uint256 _i; _i < _safeThreshold; ++_i) {
      vm.startPrank(_safeOwners[_i]);
      SAFE_PROXY.approveHash(_safeTxHash);
    }
    vm.stopPrank();

    // Execute the transaction
    canonGuard.executeTransaction(address(disapproveAction));

    // Assert if the actions builder is approved
    assertEq(canonGuard.approvalExpiries(address(actionsBuilder)), block.timestamp);
  }
}
