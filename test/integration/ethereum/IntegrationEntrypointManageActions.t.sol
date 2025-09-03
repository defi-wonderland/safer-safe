// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ApproveActionFactory} from 'contracts/factories/ApproveActionFactory.sol';
import {SetEmergencyCallerActionFactory} from 'contracts/factories/SetEmergencyCallerActionFactory.sol';
import {SetEmergencyTriggerActionFactory} from 'contracts/factories/SetEmergencyTriggerActionFactory.sol';
import {UnsetEmergencyModeActionFactory} from 'contracts/factories/UnsetEmergencyModeActionFactory.sol';
import {IEmergencyModeHook} from 'interfaces/IEmergencyModeHook.sol';
import {IApproveAction} from 'interfaces/actions-builders/IApproveAction.sol';
import {ISetEmergencyCallerAction} from 'interfaces/actions-builders/ISetEmergencyCallerAction.sol';
import {ISetEmergencyTriggerAction} from 'interfaces/actions-builders/ISetEmergencyTriggerAction.sol';
import {IUnsetEmergencyModeAction} from 'interfaces/actions-builders/IUnsetEmergencyModeAction.sol';
import {IApproveActionFactory} from 'interfaces/factories/IApproveActionFactory.sol';
import {ISetEmergencyCallerActionFactory} from 'interfaces/factories/ISetEmergencyCallerActionFactory.sol';
import {ISetEmergencyTriggerActionFactory} from 'interfaces/factories/ISetEmergencyTriggerActionFactory.sol';
import {IUnsetEmergencyModeActionFactory} from 'interfaces/factories/IUnsetEmergencyModeActionFactory.sol';
import {IntegrationEthereumBase} from 'test/integration/ethereum/IntegrationEthereumBase.sol';

contract IntegrationEntrypointManageActions is IntegrationEthereumBase {
  IApproveActionFactory public approveActionFactory;
  IApproveAction public approveAction;

  // Emergency action factories
  ISetEmergencyCallerActionFactory public setEmergencyCallerActionFactory;
  ISetEmergencyTriggerActionFactory public setEmergencyTriggerActionFactory;
  IUnsetEmergencyModeActionFactory public unsetEmergencyModeActionFactory;

  // Emergency actions
  ISetEmergencyCallerAction public setEmergencyCallerAction;
  ISetEmergencyTriggerAction public setEmergencyTriggerAction;
  IUnsetEmergencyModeAction public unsetEmergencyModeAction;

  address public actionsBuilder;
  address public newEmergencyCaller;
  address public newEmergencyTrigger;
  uint256 public constant APPROVAL_DURATION = 7 days;

  function setUp() public override {
    super.setUp();

    actionsBuilder = makeAddr('actionsBuilder');
    newEmergencyCaller = makeAddr('newEmergencyCaller');
    newEmergencyTrigger = makeAddr('newEmergencyTrigger');

    // Deploy the ApproveAction contract
    approveActionFactory = new ApproveActionFactory();
    approveAction = IApproveAction(
      approveActionFactory.createApproveAction(address(safeEntrypoint), address(actionsBuilder), APPROVAL_DURATION)
    );

    // Deploy emergency action factories
    setEmergencyCallerActionFactory = new SetEmergencyCallerActionFactory();
    setEmergencyTriggerActionFactory = new SetEmergencyTriggerActionFactory();
    unsetEmergencyModeActionFactory = new UnsetEmergencyModeActionFactory();

    // Deploy emergency actions
    setEmergencyCallerAction = ISetEmergencyCallerAction(
      setEmergencyCallerActionFactory.createSetEmergencyCallerAction(address(safeEntrypoint), newEmergencyCaller)
    );
    setEmergencyTriggerAction = ISetEmergencyTriggerAction(
      setEmergencyTriggerActionFactory.createSetEmergencyTriggerAction(address(safeEntrypoint), newEmergencyTrigger)
    );
    unsetEmergencyModeAction =
      IUnsetEmergencyModeAction(unsetEmergencyModeActionFactory.createUnsetEmergencyModeAction(address(safeEntrypoint)));
  }

  function test_ApproveActionsBuilderOrHub() public {
    // Queue the transaction
    vm.prank(_safeOwners[0]);
    safeEntrypoint.queueTransaction(address(approveAction));

    // Wait for the timelock period
    vm.warp(block.timestamp + LONG_TX_EXECUTION_DELAY);

    // Get the Safe transaction hash
    bytes32 _safeTxHash = safeEntrypoint.getSafeTransactionHash(address(approveAction));

    // Approve the Safe transaction hash
    for (uint256 _i; _i < _safeThreshold; ++_i) {
      vm.startPrank(_safeOwners[_i]);
      SAFE_PROXY.approveHash(_safeTxHash);
    }
    vm.stopPrank();

    // Execute the transaction
    safeEntrypoint.executeTransaction(address(approveAction));

    // Assert if the actions builder is approved
    assertEq(safeEntrypoint.approvalExpiries(address(actionsBuilder)), block.timestamp + APPROVAL_DURATION);
  }

  function test_EmergencyModeFlow() public {
    address _owner = _safeOwners[0];
    bytes32 _safeTxHash;

    /// 1) Set emergency caller

    // Queue the transaction
    vm.prank(_owner);
    safeEntrypoint.queueTransaction(address(setEmergencyCallerAction));

    // Wait for the timelock period
    vm.warp(block.timestamp + LONG_TX_EXECUTION_DELAY);

    // Get the Safe transaction hash
    _safeTxHash = safeEntrypoint.getSafeTransactionHash(address(setEmergencyCallerAction));

    // Approve the Safe transaction hash
    for (uint256 _i; _i < _safeThreshold; ++_i) {
      vm.startPrank(_safeOwners[_i]);
      SAFE_PROXY.approveHash(_safeTxHash);
    }
    vm.stopPrank();

    // Execute the transaction
    safeEntrypoint.executeTransaction(address(setEmergencyCallerAction));

    // Assert that the emergency caller was set
    assertEq(IEmergencyModeHook(address(safeEntrypoint)).emergencyCaller(), newEmergencyCaller);

    /// 2) Set emergency trigger

    // Queue the transaction
    vm.prank(_owner);
    safeEntrypoint.queueTransaction(address(setEmergencyTriggerAction));

    // Wait for the timelock period
    vm.warp(block.timestamp + LONG_TX_EXECUTION_DELAY);

    // Get the Safe transaction hash
    _safeTxHash = safeEntrypoint.getSafeTransactionHash(address(setEmergencyTriggerAction));

    // Approve the Safe transaction hash
    for (uint256 _i; _i < _safeThreshold; ++_i) {
      vm.startPrank(_safeOwners[_i]);
      SAFE_PROXY.approveHash(_safeTxHash);
    }
    vm.stopPrank();

    // Execute the transaction
    safeEntrypoint.executeTransaction(address(setEmergencyTriggerAction));

    // Assert that the emergency trigger was set
    assertEq(IEmergencyModeHook(address(safeEntrypoint)).emergencyTrigger(), newEmergencyTrigger);

    /// 3) Set emergency mode

    // Queue the transaction
    vm.prank(newEmergencyTrigger);
    IEmergencyModeHook(address(safeEntrypoint)).setEmergencyMode();

    // Verify emergency mode is set
    assertTrue(IEmergencyModeHook(address(safeEntrypoint)).emergencyMode());

    /// 4) Unset emergency mode

    // Queue the transaction to unset emergency mode
    vm.prank(_owner);
    safeEntrypoint.queueTransaction(address(unsetEmergencyModeAction));

    // Wait for the timelock period
    vm.warp(block.timestamp + LONG_TX_EXECUTION_DELAY);

    // Get the Safe transaction hash
    _safeTxHash = safeEntrypoint.getSafeTransactionHash(address(unsetEmergencyModeAction));

    // Approve the Safe transaction hash
    for (uint256 _i; _i < _safeThreshold; ++_i) {
      vm.startPrank(_safeOwners[_i]);
      SAFE_PROXY.approveHash(_safeTxHash);
    }
    vm.stopPrank();

    // Execute the transaction
    vm.prank(IEmergencyModeHook(address(safeEntrypoint)).emergencyCaller());
    safeEntrypoint.executeTransaction(address(unsetEmergencyModeAction));

    // Assert that emergency mode was unset
    assertFalse(IEmergencyModeHook(address(safeEntrypoint)).emergencyMode());
  }
}
