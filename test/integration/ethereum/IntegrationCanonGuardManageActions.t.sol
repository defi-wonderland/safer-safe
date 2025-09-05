// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ApproveActionFactory} from 'contracts/factories/ApproveActionFactory.sol';
import {ChangeSafeGuardActionFactory} from 'contracts/factories/ChangeSafeGuardActionFactory.sol';
import {DisapproveActionFactory} from 'contracts/factories/DisapproveActionFactory.sol';
import {SetEmergencyCallerActionFactory} from 'contracts/factories/SetEmergencyCallerActionFactory.sol';
import {SetEmergencyTriggerActionFactory} from 'contracts/factories/SetEmergencyTriggerActionFactory.sol';
import {UnsetEmergencyModeActionFactory} from 'contracts/factories/UnsetEmergencyModeActionFactory.sol';
import {IEmergencyModeHook} from 'interfaces/IEmergencyModeHook.sol';
import {IApproveAction} from 'interfaces/actions-builders/IApproveAction.sol';
import {IChangeSafeGuardAction} from 'interfaces/actions-builders/IChangeSafeGuardAction.sol';
import {IDisapproveAction} from 'interfaces/actions-builders/IDisapproveAction.sol';
import {ISetEmergencyCallerAction} from 'interfaces/actions-builders/ISetEmergencyCallerAction.sol';
import {ISetEmergencyTriggerAction} from 'interfaces/actions-builders/ISetEmergencyTriggerAction.sol';
import {ISimpleActions} from 'interfaces/actions-builders/ISimpleActions.sol';
import {IUnsetEmergencyModeAction} from 'interfaces/actions-builders/IUnsetEmergencyModeAction.sol';
import {IApproveActionFactory} from 'interfaces/factories/IApproveActionFactory.sol';
import {IChangeSafeGuardActionFactory} from 'interfaces/factories/IChangeSafeGuardActionFactory.sol';
import {IDisapproveActionFactory} from 'interfaces/factories/IDisapproveActionFactory.sol';
import {ISetEmergencyCallerActionFactory} from 'interfaces/factories/ISetEmergencyCallerActionFactory.sol';
import {ISetEmergencyTriggerActionFactory} from 'interfaces/factories/ISetEmergencyTriggerActionFactory.sol';
import {IUnsetEmergencyModeActionFactory} from 'interfaces/factories/IUnsetEmergencyModeActionFactory.sol';
import {IntegrationEthereumBase} from 'test/integration/ethereum/IntegrationEthereumBase.sol';

contract IntegrationCanonGuardManageActions is IntegrationEthereumBase {
  IApproveActionFactory public approveActionFactory;
  IApproveAction public approveAction;

  IDisapproveActionFactory public disapproveActionFactory;
  IDisapproveAction public disapproveAction;

  IChangeSafeGuardActionFactory public changeSafeGuardActionFactory;
  IChangeSafeGuardAction public changeSafeGuardAction;
  IChangeSafeGuardAction public disableSafeGuardAction;

  ISimpleActions public addOwnerSimpleActions;
  ISimpleActions public removeOwnerSimpleActions;

  // Emergency action factories
  ISetEmergencyCallerActionFactory public setEmergencyCallerActionFactory;
  ISetEmergencyTriggerActionFactory public setEmergencyTriggerActionFactory;
  IUnsetEmergencyModeActionFactory public unsetEmergencyModeActionFactory;

  // Emergency actions
  ISetEmergencyCallerAction public setEmergencyCallerAction;
  ISetEmergencyTriggerAction public setEmergencyTriggerAction;
  IUnsetEmergencyModeAction public unsetEmergencyModeAction;

  address public actionsBuilder;
  address public newSafeGuard;
  address public newOwner;
  address public ownerToRemove;
  address public previousOwner;
  address public newEmergencyCaller;
  address public newEmergencyTrigger;
  uint256 public constant APPROVAL_DURATION = 7 days;

  function setUp() public override {
    super.setUp();

    actionsBuilder = makeAddr('actionsBuilder');
    newSafeGuard = makeAddr('newSafeGuard');
    newOwner = makeAddr('newOwner');
    ownerToRemove = _safeOwners[_safeOwners.length - 1];
    previousOwner = _safeOwners[_safeOwners.length - 2];
    newEmergencyCaller = makeAddr('newEmergencyCaller');
    newEmergencyTrigger = makeAddr('newEmergencyTrigger');

    // Deploy the ApproveAction contract
    approveActionFactory = new ApproveActionFactory();
    approveAction = IApproveAction(
      approveActionFactory.createApproveAction(address(canonGuard), address(actionsBuilder), APPROVAL_DURATION)
    );

    // Deploy emergency action factories
    setEmergencyCallerActionFactory = new SetEmergencyCallerActionFactory();
    setEmergencyTriggerActionFactory = new SetEmergencyTriggerActionFactory();
    unsetEmergencyModeActionFactory = new UnsetEmergencyModeActionFactory();

    // Deploy emergency actions
    setEmergencyCallerAction = ISetEmergencyCallerAction(
      setEmergencyCallerActionFactory.createSetEmergencyCallerAction(address(canonGuard), newEmergencyCaller)
    );
    setEmergencyTriggerAction = ISetEmergencyTriggerAction(
      setEmergencyTriggerActionFactory.createSetEmergencyTriggerAction(address(canonGuard), newEmergencyTrigger)
    );
    unsetEmergencyModeAction =
      IUnsetEmergencyModeAction(unsetEmergencyModeActionFactory.createUnsetEmergencyModeAction(address(canonGuard)));

    // Deploy the DisapproveAction contract
    disapproveActionFactory = new DisapproveActionFactory();
    disapproveAction =
      IDisapproveAction(disapproveActionFactory.createDisapproveAction(address(canonGuard), address(actionsBuilder)));

    // Deploy the ChangeSafeGuardAction contract
    changeSafeGuardActionFactory = new ChangeSafeGuardActionFactory();
    changeSafeGuardAction = IChangeSafeGuardAction(
      changeSafeGuardActionFactory.createChangeSafeGuardAction(address(SAFE_PROXY), newSafeGuard)
    );

    // Deploy the ChangeSafeGuardAction contract to disable the safe guard
    disableSafeGuardAction =
      IChangeSafeGuardAction(changeSafeGuardActionFactory.createChangeSafeGuardAction(address(SAFE_PROXY), address(0)));

    // Deploy the SimpleActions contract to add an owner
    ISimpleActions.SimpleAction memory _addOwnerSimpleAction = ISimpleActions.SimpleAction({
      target: address(SAFE_PROXY),
      signature: 'addOwnerWithThreshold(address,uint256)',
      data: abi.encode(newOwner, _safeThreshold + 1),
      value: 0
    });
    ISimpleActions.SimpleAction[] memory _modifyOwnersSimpleActions = new ISimpleActions.SimpleAction[](1);
    _modifyOwnersSimpleActions[0] = _addOwnerSimpleAction;
    addOwnerSimpleActions = ISimpleActions(simpleActionsFactory.createSimpleActions(_modifyOwnersSimpleActions));

    // Deploy the SimpleActions contract to remove an owner
    ISimpleActions.SimpleAction memory _removeOwnerSimpleAction = ISimpleActions.SimpleAction({
      target: address(SAFE_PROXY),
      signature: 'removeOwner(address,address,uint256)',
      data: abi.encode(previousOwner, ownerToRemove, _safeThreshold - 1),
      value: 0
    });
    _modifyOwnersSimpleActions[0] = _removeOwnerSimpleAction;
    removeOwnerSimpleActions = ISimpleActions(simpleActionsFactory.createSimpleActions(_modifyOwnersSimpleActions));
  }

  function test_EmergencyModeFlow() public {
    address _owner = _safeOwners[0];
    bytes32 _safeTxHash;

    /// 1) Set emergency caller

    // Queue the transaction
    vm.prank(_owner);
    canonGuard.queueTransaction(address(setEmergencyCallerAction));

    // Wait for the timelock period
    vm.warp(block.timestamp + LONG_TX_EXECUTION_DELAY);

    // Get the Safe transaction hash
    _safeTxHash = canonGuard.getSafeTransactionHash(address(setEmergencyCallerAction));

    // Approve the Safe transaction hash
    for (uint256 _i; _i < _safeThreshold; ++_i) {
      vm.startPrank(_safeOwners[_i]);
      SAFE_PROXY.approveHash(_safeTxHash);
    }
    vm.stopPrank();

    // Execute the transaction
    canonGuard.executeTransaction(address(setEmergencyCallerAction));

    // Assert that the emergency caller was set
    assertEq(IEmergencyModeHook(address(canonGuard)).emergencyCaller(), newEmergencyCaller);

    /// 2) Set emergency trigger

    // Queue the transaction
    vm.prank(_owner);
    canonGuard.queueTransaction(address(setEmergencyTriggerAction));

    // Wait for the timelock period
    vm.warp(block.timestamp + LONG_TX_EXECUTION_DELAY);

    // Get the Safe transaction hash
    _safeTxHash = canonGuard.getSafeTransactionHash(address(setEmergencyTriggerAction));

    // Approve the Safe transaction hash
    for (uint256 _i; _i < _safeThreshold; ++_i) {
      vm.startPrank(_safeOwners[_i]);
      SAFE_PROXY.approveHash(_safeTxHash);
    }
    vm.stopPrank();

    // Execute the transaction
    canonGuard.executeTransaction(address(setEmergencyTriggerAction));

    // Assert that the emergency trigger was set
    assertEq(IEmergencyModeHook(address(canonGuard)).emergencyTrigger(), newEmergencyTrigger);

    /// 3) Set emergency mode

    // Queue the transaction
    vm.prank(newEmergencyTrigger);
    IEmergencyModeHook(address(canonGuard)).setEmergencyMode();

    // Verify emergency mode is set
    assertTrue(IEmergencyModeHook(address(canonGuard)).emergencyMode());

    /// 4) Unset emergency mode

    // Queue the transaction to unset emergency mode
    vm.prank(_owner);
    canonGuard.queueTransaction(address(unsetEmergencyModeAction));

    // Wait for the timelock period
    vm.warp(block.timestamp + LONG_TX_EXECUTION_DELAY);

    // Get the Safe transaction hash
    _safeTxHash = canonGuard.getSafeTransactionHash(address(unsetEmergencyModeAction));

    // Approve the Safe transaction hash
    for (uint256 _i; _i < _safeThreshold; ++_i) {
      vm.startPrank(_safeOwners[_i]);
      SAFE_PROXY.approveHash(_safeTxHash);
    }
    vm.stopPrank();

    // Execute the transaction
    vm.prank(IEmergencyModeHook(address(canonGuard)).emergencyCaller());
    canonGuard.executeTransaction(address(unsetEmergencyModeAction));

    // Assert that emergency mode was unset
    assertFalse(IEmergencyModeHook(address(canonGuard)).emergencyMode());
  }

  function test_ApproveActionsBuilderOrHub() public {
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

  function test_ChangeSafeGuard() public {
    // Queue the transaction
    vm.prank(_safeOwners[0]);
    canonGuard.queueTransaction(address(changeSafeGuardAction));

    // Wait for the timelock period
    vm.warp(block.timestamp + LONG_TX_EXECUTION_DELAY);

    // Get the Safe transaction hash
    bytes32 _safeTxHash = canonGuard.getSafeTransactionHash(address(changeSafeGuardAction));

    // Approve the Safe transaction hash
    for (uint256 _i; _i < _safeThreshold; ++_i) {
      vm.startPrank(_safeOwners[_i]);
      SAFE_PROXY.approveHash(_safeTxHash);
    }
    vm.stopPrank();

    // Execute the transaction
    canonGuard.executeTransaction(address(changeSafeGuardAction));

    // Assert if the safe guard is changed
    bytes32 _guardSlot = vm.load(address(SAFE_PROXY), keccak256('guard_manager.guard.address'));
    assertEq(address(uint160(uint256(_guardSlot))), newSafeGuard);
  }

  function test_DisableSafeGuard() public {
    // Queue the transaction
    vm.prank(_safeOwners[0]);
    canonGuard.queueTransaction(address(disableSafeGuardAction));

    // Wait for the timelock period
    vm.warp(block.timestamp + LONG_TX_EXECUTION_DELAY);

    // Get the Safe transaction hash
    bytes32 _safeTxHash = canonGuard.getSafeTransactionHash(address(disableSafeGuardAction));

    // Approve the Safe transaction hash
    for (uint256 _i; _i < _safeThreshold; ++_i) {
      vm.startPrank(_safeOwners[_i]);
      SAFE_PROXY.approveHash(_safeTxHash);
    }
    vm.stopPrank();

    // Execute the transaction
    canonGuard.executeTransaction(address(disableSafeGuardAction));

    // Assert if the safe guard is changed
    bytes32 _guardSlot = vm.load(address(SAFE_PROXY), keccak256('guard_manager.guard.address'));
    assertEq(address(uint160(uint256(_guardSlot))), address(0));
  }

  function test_AddOwnerWithNewThreshold() public {
    // Queue the transaction
    vm.prank(_safeOwners[0]);
    canonGuard.queueTransaction(address(addOwnerSimpleActions));

    // Wait for the timelock period
    vm.warp(block.timestamp + LONG_TX_EXECUTION_DELAY);

    // Get the Safe transaction hash
    bytes32 _safeTxHash = canonGuard.getSafeTransactionHash(address(addOwnerSimpleActions));

    // Approve the Safe transaction hash
    for (uint256 _i; _i < _safeThreshold; ++_i) {
      vm.startPrank(_safeOwners[_i]);
      SAFE_PROXY.approveHash(_safeTxHash);
    }
    vm.stopPrank();

    // Execute the transaction
    canonGuard.executeTransaction(address(addOwnerSimpleActions));

    // Assert if the owner is added
    assertEq(SAFE_PROXY.isOwner(newOwner), true);
    assertEq(SAFE_PROXY.getThreshold(), _safeThreshold + 1);
  }

  function test_RemoveOwnerWithNewThreshold() public {
    // Queue the transaction
    vm.prank(_safeOwners[0]);
    canonGuard.queueTransaction(address(removeOwnerSimpleActions));

    // Wait for the timelock period
    vm.warp(block.timestamp + LONG_TX_EXECUTION_DELAY);

    // Get the Safe transaction hash
    bytes32 _safeTxHash = canonGuard.getSafeTransactionHash(address(removeOwnerSimpleActions));

    // Approve the Safe transaction hash
    for (uint256 _i; _i < _safeThreshold; ++_i) {
      vm.startPrank(_safeOwners[_i]);
      SAFE_PROXY.approveHash(_safeTxHash);
    }
    vm.stopPrank();

    // Execute the transaction
    canonGuard.executeTransaction(address(removeOwnerSimpleActions));

    // Assert if the owner is removed
    assertEq(SAFE_PROXY.isOwner(ownerToRemove), false);
    assertEq(SAFE_PROXY.getThreshold(), _safeThreshold - 1);
  }

  function test_ExecuteTransactionInSimulationMode() public {
    // Queue the transaction
    vm.prank(_safeOwners[0]);
    canonGuard.queueTransaction(address(removeOwnerSimpleActions));

    // Wait for the timelock period
    vm.warp(block.timestamp + LONG_TX_EXECUTION_DELAY);

    // Get the Safe transaction hash
    bytes32 _safeTxHash = canonGuard.getSafeTransactionHash(address(removeOwnerSimpleActions));

    // sets _isSimulation to true
    vm.store(address(canonGuard), bytes32(uint256(4)), bytes32(uint256(1)));

    vm.prank(address(canonGuard));
    SAFE_PROXY.approveHash(_safeTxHash);

    // Execute the transaction
    canonGuard.executeTransaction(address(removeOwnerSimpleActions));

    // Assert if the owner is removed
    assertEq(SAFE_PROXY.isOwner(ownerToRemove), false);
    assertEq(SAFE_PROXY.getThreshold(), _safeThreshold - 1);
  }
}
