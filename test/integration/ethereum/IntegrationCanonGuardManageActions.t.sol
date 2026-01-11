// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IEmergencyModeHook} from 'interfaces/IEmergencyModeHook.sol';
import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';
import {IArbitraryActions} from 'interfaces/actions-builders/IArbitraryActions.sol';
import {IChangeSafeGuardAction} from 'interfaces/actions-builders/IChangeSafeGuardAction.sol';
import {IPreApproveAction} from 'interfaces/actions-builders/IPreApproveAction.sol';
import {ISetEmergencyCallerAction} from 'interfaces/actions-builders/ISetEmergencyCallerAction.sol';
import {ISetEmergencyTriggerAction} from 'interfaces/actions-builders/ISetEmergencyTriggerAction.sol';
import {LibSort} from 'solady/utils/LibSort.sol';
import {IntegrationEthereumBase} from 'test/integration/ethereum/IntegrationEthereumBase.sol';

contract IntegrationCanonGuardManageActions is IntegrationEthereumBase {
  using LibSort for address[];

  IPreApproveAction public preApproveAction;
  IPreApproveAction public disapproveAction;

  IChangeSafeGuardAction public changeSafeGuardAction;
  IChangeSafeGuardAction public disableSafeGuardAction;

  IArbitraryActions public addOwnerArbitraryActions;
  IArbitraryActions public removeOwnerArbitraryActions;

  // Emergency actions
  ISetEmergencyCallerAction public setEmergencyCallerAction;
  ISetEmergencyTriggerAction public setEmergencyTriggerAction;

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

    // Deploy the PreApproveAction contract for both approve and disapprove
    preApproveAction =
      IPreApproveAction(preApproveActionFactory.createPreApproveAction(address(actionsBuilder), APPROVAL_DURATION));
    disapproveAction = IPreApproveAction(preApproveActionFactory.createPreApproveAction(address(actionsBuilder), 0));

    // Deploy emergency actions
    setEmergencyCallerAction =
      ISetEmergencyCallerAction(setEmergencyCallerActionFactory.createSetEmergencyCallerAction(newEmergencyCaller));
    setEmergencyTriggerAction =
      ISetEmergencyTriggerAction(setEmergencyTriggerActionFactory.createSetEmergencyTriggerAction(newEmergencyTrigger));

    // Deploy the ChangeSafeGuardAction contract
    changeSafeGuardAction =
      IChangeSafeGuardAction(changeSafeGuardActionFactory.createChangeSafeGuardAction(newSafeGuard));

    // Deploy the ChangeSafeGuardAction contract to disable the safe guard
    disableSafeGuardAction =
      IChangeSafeGuardAction(changeSafeGuardActionFactory.createChangeSafeGuardAction(address(0)));

    // Deploy the ArbitraryActions contract to add an owner
    IArbitraryActions.ArbitraryAction memory _addOwnerArbitraryAction = IArbitraryActions.ArbitraryAction({
      target: address(SAFE_PROXY),
      signature: 'addOwnerWithThreshold(address,uint256)',
      data: abi.encode(newOwner, _safeThreshold + 1),
      value: 0
    });
    IArbitraryActions.ArbitraryAction[] memory _modifyOwnersArbitraryActions =
      new IArbitraryActions.ArbitraryAction[](1);
    _modifyOwnersArbitraryActions[0] = _addOwnerArbitraryAction;
    addOwnerArbitraryActions =
      IArbitraryActions(arbitraryActionsFactory.createArbitraryActions(_modifyOwnersArbitraryActions));

    // Deploy the ArbitraryActions contract to remove an owner
    IArbitraryActions.ArbitraryAction memory _removeOwnerArbitraryAction = IArbitraryActions.ArbitraryAction({
      target: address(SAFE_PROXY),
      signature: 'removeOwner(address,address,uint256)',
      data: abi.encode(previousOwner, ownerToRemove, _safeThreshold - 1),
      value: 0
    });
    _modifyOwnersArbitraryActions[0] = _removeOwnerArbitraryAction;
    removeOwnerArbitraryActions =
      IArbitraryActions(arbitraryActionsFactory.createArbitraryActions(_modifyOwnersArbitraryActions));
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
    canonGuard.queueTransaction(address(preApproveAction));

    // Wait for the timelock period
    vm.warp(block.timestamp + LONG_TX_EXECUTION_DELAY);

    // Get the Safe transaction hash
    bytes32 _safeTxHash = canonGuard.getSafeTransactionHash(address(preApproveAction));

    // Approve the Safe transaction hash
    for (uint256 _i; _i < _safeThreshold; ++_i) {
      vm.startPrank(_safeOwners[_i]);
      SAFE_PROXY.approveHash(_safeTxHash);
    }
    vm.stopPrank();

    // Execute the transaction
    canonGuard.executeTransaction(address(preApproveAction));

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
    canonGuard.queueTransaction(address(addOwnerArbitraryActions));

    // Wait for the timelock period
    vm.warp(block.timestamp + LONG_TX_EXECUTION_DELAY);

    // Get the Safe transaction hash
    bytes32 _safeTxHash = canonGuard.getSafeTransactionHash(address(addOwnerArbitraryActions));

    // Approve the Safe transaction hash
    for (uint256 _i; _i < _safeThreshold; ++_i) {
      vm.startPrank(_safeOwners[_i]);
      SAFE_PROXY.approveHash(_safeTxHash);
    }
    vm.stopPrank();

    // Execute the transaction
    canonGuard.executeTransaction(address(addOwnerArbitraryActions));

    // Assert if the owner is added
    assertEq(SAFE_PROXY.isOwner(newOwner), true);
    assertEq(SAFE_PROXY.getThreshold(), _safeThreshold + 1);
  }

  function test_RemoveOwnerWithNewThreshold() public {
    // Queue the transaction
    vm.prank(_safeOwners[0]);
    canonGuard.queueTransaction(address(removeOwnerArbitraryActions));

    // Wait for the timelock period
    vm.warp(block.timestamp + LONG_TX_EXECUTION_DELAY);

    // Get the Safe transaction hash
    bytes32 _safeTxHash = canonGuard.getSafeTransactionHash(address(removeOwnerArbitraryActions));

    // Approve the Safe transaction hash
    for (uint256 _i; _i < _safeThreshold; ++_i) {
      vm.startPrank(_safeOwners[_i]);
      SAFE_PROXY.approveHash(_safeTxHash);
    }
    vm.stopPrank();

    // Execute the transaction
    canonGuard.executeTransaction(address(removeOwnerArbitraryActions));

    // Assert if the owner is removed
    assertEq(SAFE_PROXY.isOwner(ownerToRemove), false);
    assertEq(SAFE_PROXY.getThreshold(), _safeThreshold - 1);
  }

  function test_ExecuteTransactionInSimulationMode() public {
    // Queue the transaction
    vm.prank(_safeOwners[0]);
    canonGuard.queueTransaction(address(setEmergencyCallerAction));

    // Wait for the timelock period
    vm.warp(block.timestamp + LONG_TX_EXECUTION_DELAY);

    // Adds canon guard as the new owner and sets the threshold to 1
    vm.prank(address(SAFE_PROXY));
    SAFE_PROXY.addOwnerWithThreshold(address(canonGuard), 1);

    assertEq(SAFE_PROXY.getThreshold(), 1);
    assertEq(SAFE_PROXY.isOwner(address(canonGuard)), true);

    // sets _isSimulation to true
    vm.store(address(canonGuard), bytes32(uint256(4)), bytes32(uint256(1)));

    // Execute the transaction
    canonGuard.executeTransaction(address(setEmergencyCallerAction));

    // Assert that the emergency caller was set
    assertEq(IEmergencyModeHook(address(canonGuard)).emergencyCaller(), newEmergencyCaller);
  }

  function test_CancelEnqueuedTransaction() public {
    // Queue the transaction
    vm.prank(_safeOwners[0]);
    canonGuard.queueTransaction(address(addOwnerArbitraryActions));
    (address _proposer, bytes memory _actionsData, uint256 _executableAt, uint256 _expiresAt, bool _isPreApproved) =
      canonGuard.transactionsInfo(address(addOwnerArbitraryActions));
    assertEq(_proposer, _safeOwners[0]);
    assertGt(_actionsData.length, 0);
    assertEq(_executableAt, block.timestamp + LONG_TX_EXECUTION_DELAY);
    assertEq(_expiresAt, block.timestamp + LONG_TX_EXECUTION_DELAY + TX_EXPIRY_DELAY);
    assertEq(_isPreApproved, false);

    // Cancel the transaction
    vm.prank(_safeOwners[0]);
    canonGuard.cancelEnqueuedTransaction(address(addOwnerArbitraryActions));

    (_proposer, _actionsData, _executableAt, _expiresAt, _isPreApproved) =
      canonGuard.transactionsInfo(address(addOwnerArbitraryActions));

    assertEq(_proposer, address(0));
    assertEq(_actionsData, bytes(''));
    assertEq(_executableAt, 0);
    assertEq(_expiresAt, 0);
    assertEq(_isPreApproved, false);
  }

  function test_ExecuteNoActionTransaction() public {
    // Get the safe nonce
    uint256 _safeNonce = canonGuard.getSafeNonce();

    // Queue a random transaction
    vm.prank(_safeOwners[0]);
    canonGuard.queueTransaction(address(addOwnerArbitraryActions));

    // Approve the Safe transaction hash
    bytes32 _safeTxHash = canonGuard.getSafeTransactionHash(address(addOwnerArbitraryActions));
    for (uint256 _i; _i < _safeThreshold; ++_i) {
      vm.startPrank(_safeOwners[_i]);
      SAFE_PROXY.approveHash(_safeTxHash);
    }
    vm.stopPrank();

    // Approve the Safe empty transaction hash
    bytes32 _safeEmptyTxHash = canonGuard.getSafeTransactionHash(address(0), _safeNonce);
    for (uint256 _i; _i < _safeThreshold; ++_i) {
      vm.startPrank(_safeOwners[_i]);
      SAFE_PROXY.approveHash(_safeEmptyTxHash);
    }
    vm.stopPrank();

    // Execute empty transaction in order to use the safe nonce
    canonGuard.executeNoActionTransaction();

    // Nonce increased
    assertEq(canonGuard.getSafeNonce(), _safeNonce + 1);

    // Wait for the timelock period
    vm.warp(block.timestamp + LONG_TX_EXECUTION_DELAY);

    // The first tx is no longer valid
    vm.expectRevert('GS020');
    canonGuard.executeTransaction(address(addOwnerArbitraryActions));
  }

  function test_GetQueuedActionBuildersInfo() public {
    // Queue the transaction
    vm.prank(_safeOwners[0]);
    canonGuard.queueTransaction(address(setEmergencyCallerAction));

    uint256 _originalBlockTimestamp = block.timestamp;

    preApproveAction = IPreApproveAction(
      preApproveActionFactory.createPreApproveAction(address(setEmergencyCallerAction), APPROVAL_DURATION)
    );

    vm.prank(_safeOwners[0]);
    canonGuard.queueTransaction(address(preApproveAction));
    vm.warp(block.timestamp + LONG_TX_EXECUTION_DELAY);
    bytes32 _safeTxHash = canonGuard.getSafeTransactionHash(address(preApproveAction));
    for (uint256 _i; _i < _safeThreshold; ++_i) {
      vm.startPrank(_safeOwners[_i]);
      SAFE_PROXY.approveHash(_safeTxHash);
    }
    vm.stopPrank();
    canonGuard.executeTransaction(address(preApproveAction));

    // Get the queued action builders info
    address[] memory _queuedActionBuilders = canonGuard.getQueuedActionBuilders();
    assertEq(_queuedActionBuilders.length, 1);
    assertEq(_queuedActionBuilders[0], address(setEmergencyCallerAction));

    (address _proposer, bytes memory _actionsData, uint256 _executableAt, uint256 _expiresAt, bool _isPreApproved) =
      canonGuard.transactionsInfo(address(setEmergencyCallerAction));
    IActionsBuilder.Action[] memory _decodedActionsData = abi.decode(_actionsData, (IActionsBuilder.Action[]));
    assertEq(_proposer, _safeOwners[0]);
    assertEq(_decodedActionsData[0].target, address(canonGuard));
    assertEq(_decodedActionsData[0].data, abi.encodeCall(IEmergencyModeHook.setEmergencyCaller, newEmergencyCaller));
    assertEq(_decodedActionsData[0].value, 0);
    assertEq(_executableAt, _originalBlockTimestamp + LONG_TX_EXECUTION_DELAY);
    assertEq(_expiresAt, _executableAt + TX_EXPIRY_DELAY);
    assertEq(_isPreApproved, false);

    uint256 _approvalExpiresAt = canonGuard.approvalExpiries(address(setEmergencyCallerAction));
    assertEq(_approvalExpiresAt, block.timestamp + APPROVAL_DURATION);
  }

  function test_ExecuteTransactions() public {
    deal(address(WETH), address(SAFE_PROXY), 1 ether);
    deal(address(USDC), address(SAFE_PROXY), 1 ether);
    address _recipient = makeAddr('recipient');
    address _wethTransferArbitraryAction = arbitraryActionsFactory.createArbitraryAction(
      IArbitraryActions.ArbitraryAction({
        target: address(WETH), signature: 'transfer(address,uint256)', data: abi.encode(_recipient, 1 ether), value: 0
      })
    );

    address _usdcTransferArbitraryAction = arbitraryActionsFactory.createArbitraryAction(
      IArbitraryActions.ArbitraryAction({
        target: address(USDC), signature: 'transfer(address,uint256)', data: abi.encode(_recipient, 1 ether), value: 0
      })
    );

    // Queue the transactions
    vm.prank(_safeOwners[0]);
    canonGuard.queueTransaction(address(_wethTransferArbitraryAction));
    vm.prank(_safeOwners[0]);
    canonGuard.queueTransaction(address(_usdcTransferArbitraryAction));

    uint256 _safeNonce = canonGuard.getSafeNonce();

    vm.warp(block.timestamp + LONG_TX_EXECUTION_DELAY);
    bytes32 _safeTxHashA = canonGuard.getSafeTransactionHash(address(_wethTransferArbitraryAction), _safeNonce);
    bytes32 _safeTxHashB = canonGuard.getSafeTransactionHash(address(_usdcTransferArbitraryAction), _safeNonce + 1);
    for (uint256 _i; _i < _safeThreshold; ++_i) {
      vm.startPrank(_safeOwners[_i]);
      SAFE_PROXY.approveHash(_safeTxHashA);
      SAFE_PROXY.approveHash(_safeTxHashB);
      vm.stopPrank();
    }

    // Execute the transactions in the wrong order
    address[] memory _actionsBuilders = new address[](2);
    _actionsBuilders[0] = address(_usdcTransferArbitraryAction);
    _actionsBuilders[1] = address(_wethTransferArbitraryAction);
    vm.expectRevert('GS020');
    canonGuard.executeTransactions(_actionsBuilders);

    // Execute the transactions in the correct order
    _actionsBuilders[0] = address(_wethTransferArbitraryAction);
    _actionsBuilders[1] = address(_usdcTransferArbitraryAction);
    canonGuard.executeTransactions(_actionsBuilders);

    // Assert that the transactions were executed
    assertEq(WETH.balanceOf(address(SAFE_PROXY)), 0);
    assertEq(USDC.balanceOf(address(SAFE_PROXY)), 0);
    assertEq(WETH.balanceOf(_recipient), 1 ether);
    assertEq(USDC.balanceOf(_recipient), 1 ether);
  }

  function test_SetGuardAction() public {
    // Remove the current guard
    vm.prank(address(SAFE_PROXY));
    SAFE_PROXY.setGuard(address(0));

    // Queue the transaction
    vm.prank(_safeOwners[0]);
    canonGuard.queueTransaction(address(setGuardAction));

    // Wait for the timelock period
    vm.warp(block.timestamp + LONG_TX_EXECUTION_DELAY);

    // Get the Safe transaction hash
    bytes32 _safeTxHash = canonGuard.getSafeTransactionHash(address(setGuardAction));

    // Approve the Safe transaction hash
    for (uint256 _i; _i < _safeThreshold; ++_i) {
      vm.startPrank(_safeOwners[_i]);
      SAFE_PROXY.approveHash(_safeTxHash);
    }
    vm.stopPrank();

    // Execute the transaction
    canonGuard.executeTransaction(address(setGuardAction));

    // Assert that the guard has been set to the canon guard
    bytes32 _guardSlot = vm.load(address(SAFE_PROXY), keccak256('guard_manager.guard.address'));
    assertEq(address(uint160(uint256(_guardSlot))), address(canonGuard));
  }

  function test_CollectDust() public {
    // Send ETH to the canon guard
    vm.deal(address(canonGuard), 1 ether);

    uint256 _safeETHBalanceBefore = address(SAFE_PROXY).balance;

    // Collect the dust
    canonGuard.collectDust(canonGuard.ETH_ADDRESS());

    // Assert that the ETH has been collected
    assertEq(address(SAFE_PROXY).balance, _safeETHBalanceBefore + 1 ether);

    // Send WETH to the canon guard
    deal(address(WETH), address(canonGuard), 1 ether);

    uint256 _safeWETHBalanceBefore = WETH.balanceOf(address(SAFE_PROXY));

    // Collect the WETH
    canonGuard.collectDust(address(WETH));

    // Assert that the WETH has been collected
    assertEq(WETH.balanceOf(address(SAFE_PROXY)), _safeWETHBalanceBefore + 1 ether);
  }

  function test_ExecuteTransactionWithSingleETHTransfer() public {
    address _recipient = makeAddr('ethRecipient');
    address _executor = makeAddr('executor');
    uint256 _ethAmount = 0.5 ether;

    // Create an ArbitraryAction that sends ETH to the recipient
    IArbitraryActions.ArbitraryAction memory _ethTransferAction =
      IArbitraryActions.ArbitraryAction({target: _recipient, signature: '', data: '', value: _ethAmount});

    IArbitraryActions.ArbitraryAction[] memory _ethTransferActions = new IArbitraryActions.ArbitraryAction[](1);
    _ethTransferActions[0] = _ethTransferAction;
    address _ethTransferArbitraryAction = arbitraryActionsFactory.createArbitraryActions(_ethTransferActions);

    // Give some ETH to executor and send it to the SAFE
    vm.deal(_executor, _ethAmount);
    vm.prank(_executor);
    (bool _success,) = payable(address(SAFE_PROXY)).call{value: _ethAmount}('');
    assertTrue(_success);

    // Record initial balances
    uint256 _executorInitialBalance = _executor.balance;
    uint256 _recipientInitialBalance = _recipient.balance;
    uint256 _safeInitialBalance = address(SAFE_PROXY).balance;
    uint256 _canonGuardInitialBalance = address(canonGuard).balance;

    // Queue the transaction
    vm.prank(_safeOwners[0]);
    canonGuard.queueTransaction(_ethTransferArbitraryAction);

    // Wait for the timelock period
    vm.warp(block.timestamp + LONG_TX_EXECUTION_DELAY);

    // Get the Safe transaction hash
    bytes32 _safeTxHash = canonGuard.getSafeTransactionHash(_ethTransferArbitraryAction);

    // Approve the Safe transaction hash
    for (uint256 _i; _i < _safeThreshold; ++_i) {
      vm.startPrank(_safeOwners[_i]);
      SAFE_PROXY.approveHash(_safeTxHash);
    }
    vm.stopPrank();

    // Execute the transaction
    vm.prank(_executor);
    canonGuard.executeTransaction(_ethTransferArbitraryAction);

    // Record final balances
    uint256 _executorFinalBalance = _executor.balance;
    uint256 _recipientFinalBalance = _recipient.balance;
    uint256 _safeFinalBalance = address(SAFE_PROXY).balance;
    uint256 _canonGuardFinalBalance = address(canonGuard).balance;

    // Verify ETH flow: executor -> canonGuard -> safe -> recipient
    assertEq(_executorFinalBalance, _executorInitialBalance, 'Executor should remain unchanged');
    assertEq(_recipientFinalBalance, _recipientInitialBalance + _ethAmount, 'Recipient should have received ETH');
    assertEq(_safeFinalBalance, _safeInitialBalance - _ethAmount, 'Safe balance should have sent ETH');
    assertEq(_canonGuardFinalBalance, _canonGuardInitialBalance, 'CanonGuard balance should remain unchanged');
  }

  function test_ExecuteTransactionWithBatchETHTransfer() public {
    address _alice = makeAddr('ALICE');
    address _bob = makeAddr('BOB');
    address _executor = makeAddr('executor');

    // Create 2 ArbitraryActions that send 1 and 2 ether to the recipients
    address _ethTransferArbitraryAction0;
    address _ethTransferArbitraryAction1;
    {
      IArbitraryActions.ArbitraryAction memory _ethTransferAction1 =
        IArbitraryActions.ArbitraryAction({target: _alice, signature: '', data: '', value: 1 ether});
      IArbitraryActions.ArbitraryAction memory _ethTransferAction2 =
        IArbitraryActions.ArbitraryAction({target: _bob, signature: '', data: '', value: 2 ether});

      IArbitraryActions.ArbitraryAction[] memory _ethTransferActions0 = new IArbitraryActions.ArbitraryAction[](2);
      _ethTransferActions0[0] = _ethTransferAction1;
      _ethTransferActions0[1] = _ethTransferAction2;
      _ethTransferArbitraryAction0 = arbitraryActionsFactory.createArbitraryActions(_ethTransferActions0);

      // Create 2 ArbitraryActions that send 3 and 4 ether to the recipients
      IArbitraryActions.ArbitraryAction memory _ethTransferAction3 =
        IArbitraryActions.ArbitraryAction({target: _bob, signature: '', data: '', value: 3 ether});
      IArbitraryActions.ArbitraryAction memory _ethTransferAction4 =
        IArbitraryActions.ArbitraryAction({target: _alice, signature: '', data: '', value: 4 ether});

      IArbitraryActions.ArbitraryAction[] memory _ethTransferActions1 = new IArbitraryActions.ArbitraryAction[](2);
      _ethTransferActions1[0] = _ethTransferAction3;
      _ethTransferActions1[1] = _ethTransferAction4;
      _ethTransferArbitraryAction1 = arbitraryActionsFactory.createArbitraryActions(_ethTransferActions1);
    }

    // Give some ETH to executor and send it to the SAFE
    vm.deal(_executor, 10 ether);
    vm.prank(_executor);
    (bool _success,) = payable(address(SAFE_PROXY)).call{value: 10 ether}('');
    assertTrue(_success);

    // Record initial balances
    uint256 _executorInitialBalance = _executor.balance;
    uint256 _aliceInitialBalance = _alice.balance;
    uint256 _bobInitialBalance = _bob.balance;
    uint256 _safeInitialBalance = address(SAFE_PROXY).balance;
    uint256 _canonGuardInitialBalance = address(canonGuard).balance;

    // Queue the transaction
    vm.prank(_safeOwners[0]);
    canonGuard.queueTransaction(_ethTransferArbitraryAction0);
    vm.prank(_safeOwners[0]);
    canonGuard.queueTransaction(_ethTransferArbitraryAction1);

    // Wait for the timelock period
    vm.warp(block.timestamp + LONG_TX_EXECUTION_DELAY);

    {
      // Get the Safe transaction hash
      bytes32 _safeTxHashA = canonGuard.getSafeTransactionHash(_ethTransferArbitraryAction0);
      bytes32 _safeTxHashB = canonGuard.getSafeTransactionHash(_ethTransferArbitraryAction1, SAFE_PROXY.nonce() + 1);

      // Approve the Safe transaction hash
      for (uint256 _i; _i < _safeThreshold; ++_i) {
        vm.startPrank(_safeOwners[_i]);
        SAFE_PROXY.approveHash(_safeTxHashA);
        SAFE_PROXY.approveHash(_safeTxHashB);
      }
      vm.stopPrank();
    }

    // Execute the transaction
    {
      vm.prank(_executor);
      address[] memory _actionsBuilders = new address[](2);
      _actionsBuilders[0] = _ethTransferArbitraryAction0;
      _actionsBuilders[1] = _ethTransferArbitraryAction1;
      canonGuard.executeTransactions(_actionsBuilders);
    }

    // Verify ETH flow: executor -> canonGuard -> safe -> recipients
    assertEq(_executor.balance, _executorInitialBalance, 'Executor should remain unchanged');
    assertEq(_alice.balance, _aliceInitialBalance + 5 ether, 'Alice should have received 5 ETH (1+4)');
    assertEq(_bob.balance, _bobInitialBalance + 5 ether, 'Bob should have received 5 ETH (2+3)');
    assertEq(address(SAFE_PROXY).balance, _safeInitialBalance - 10 ether, 'Safe balance should have sent 10 ETH total');
    assertEq(address(canonGuard).balance, _canonGuardInitialBalance, 'CanonGuard balance should remain unchanged');
  }

  function test_ExecuteTransactionWithSingleETHTransferWithNoFundsInSAFE() public {
    address _alice = makeAddr('ALICE');
    address _executor = makeAddr('executor');

    // Create an ArbitraryAction that tries to send 1 ether to Alice
    address _ethTransferArbitraryAction;
    {
      IArbitraryActions.ArbitraryAction memory _ethTransferAction =
        IArbitraryActions.ArbitraryAction({target: _alice, signature: '', data: '', value: 1 ether});

      IArbitraryActions.ArbitraryAction[] memory _ethTransferActions = new IArbitraryActions.ArbitraryAction[](1);
      _ethTransferActions[0] = _ethTransferAction;
      _ethTransferArbitraryAction = arbitraryActionsFactory.createArbitraryActions(_ethTransferActions);
    }

    // Ensure SAFE has zero ETH balance (it should be zero by default, but make it explicit)
    vm.deal(address(SAFE_PROXY), 0);

    // Queue the transaction
    vm.prank(_safeOwners[0]);
    canonGuard.queueTransaction(_ethTransferArbitraryAction);

    // Wait for the timelock period
    vm.warp(block.timestamp + LONG_TX_EXECUTION_DELAY);

    {
      // Get the Safe transaction hash
      bytes32 _safeTxHash = canonGuard.getSafeTransactionHash(_ethTransferArbitraryAction);

      // Approve the Safe transaction hash
      for (uint256 _i; _i < _safeThreshold; ++_i) {
        vm.startPrank(_safeOwners[_i]);
        SAFE_PROXY.approveHash(_safeTxHash);
      }
      vm.stopPrank();
    }

    // Execute the transaction and expect it to fail due to insufficient funds
    {
      vm.prank(_executor);
      address[] memory _actionsBuilders = new address[](1);
      _actionsBuilders[0] = _ethTransferArbitraryAction;

      vm.expectRevert();
      canonGuard.executeTransactions(_actionsBuilders);
    }
  }

  function test_SortSigners() public {
    // Add 3 more owners to the Safe
    vm.startPrank(address(SAFE_PROXY));
    SAFE_PROXY.addOwnerWithThreshold(makeAddr('owner1'), 1);
    SAFE_PROXY.addOwnerWithThreshold(makeAddr('owner2'), 1);
    SAFE_PROXY.addOwnerWithThreshold(makeAddr('owner3'), 1);
    vm.stopPrank();

    // Check that the owners array is unsorted (`getOwners()` is called inside of `_getApprovedHashSigners()` function)
    address[] memory _owners = SAFE_PROXY.getOwners();
    assertFalse(_owners.isSorted());

    // Approve the Safe empty transaction hash
    bytes32 _safeEmptyTxHash = canonGuard.getSafeTransactionHash(address(0));
    for (uint256 _i; _i < _safeThreshold; ++_i) {
      vm.startPrank(_owners[_i]);
      SAFE_PROXY.approveHash(_safeEmptyTxHash);
    }
    vm.stopPrank();

    // Execute empty transaction. It should succeed given that the array was sorted inside the function
    canonGuard.executeNoActionTransaction();
  }
}
