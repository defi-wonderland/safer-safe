// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ISimpleTransfers} from 'interfaces/actions-builders/ISimpleTransfers.sol';

import {IntegrationOptimismBase} from 'test/integration/optimism/IntegrationOptimismBase.sol';

contract IntegrationWonderlandTransfers is IntegrationOptimismBase {
  // ~~~ ACTIONS ~~~
  address internal _actionsBuilder;
  address internal _bonusesPullSplit = 0x689b5182a50e76Efab2076865C1242E69Ec74E4e;

  function setUp() public override {
    super.setUp();

    // Deploy the SimpleTransfers contract
    ISimpleTransfers.TransferAction memory _bonusesTransferAction =
      ISimpleTransfers.TransferAction({token: address(KITE), to: _bonusesPullSplit, amount: _safeBalance});

    ISimpleTransfers.TransferAction[] memory _transferActions = new ISimpleTransfers.TransferAction[](1);
    _transferActions[0] = _bonusesTransferAction;

    _actionsBuilder = simpleTransfersFactory.createSimpleTransfers(_transferActions);
  }

  function test_ExecuteTransaction() public {
    // Allow the CanonGuard to call the SimpleTransfers contract
    uint256 _approvalDuration = 1 days;

    vm.prank(address(SAFE_PROXY));
    canonGuard.approveActionsBuilderOrHub(_actionsBuilder, _approvalDuration);

    // Queue the transaction
    vm.prank(_safeOwners[0]);
    canonGuard.queueTransaction(_actionsBuilder);

    // Wait for the timelock period
    vm.warp(block.timestamp + SHORT_TX_EXECUTION_DELAY);

    // Get the Safe transaction hash
    bytes32 _safeTxHash = canonGuard.getSafeTransactionHash(_actionsBuilder);

    // Approve the Safe transaction hash
    for (uint256 _i; _i < _safeThreshold; ++_i) {
      vm.startPrank(_safeOwners[_i]);
      SAFE_PROXY.approveHash(_safeTxHash);
    }
    vm.stopPrank();

    // Execute the transaction
    canonGuard.executeTransaction(_actionsBuilder);

    // Assert the token balances
    assertEq(KITE.balanceOf(_bonusesPullSplit), _safeBalance);
    assertEq(KITE.balanceOf(address(SAFE_PROXY)), 0);
  }
}
