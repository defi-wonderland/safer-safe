// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ISimpleTransfers} from 'interfaces/actions-builders/ISimpleTransfers.sol';

import {IntegrationEthereumBase} from 'test/integration/ethereum/IntegrationEthereumBase.sol';

contract IntegrationWonderlandTransfers is IntegrationEthereumBase {
  // ~~~ ACTIONS ~~~
  address internal _actionsBuilder;
  address internal _salariesDeposit = 0xa7242329Fa88d501f2D2Abe7d63FFC8C5dA38A99;
  address internal _bonusesPullSplit = 0xDf7cA886c57f0937cA0C0b9E06F40896ed9F8392;

  function setUp() public override {
    super.setUp();

    // Deploy the SimpleTransfers contract
    ISimpleTransfers.TransferAction memory _salariesTransferAction =
      ISimpleTransfers.TransferAction({token: address(USDC), to: _salariesDeposit, amount: _safeBalance});
    ISimpleTransfers.TransferAction memory _bonusesTransferAction =
      ISimpleTransfers.TransferAction({token: address(GRT), to: _bonusesPullSplit, amount: _safeBalance});

    ISimpleTransfers.TransferAction[] memory _transferActions = new ISimpleTransfers.TransferAction[](2);
    _transferActions[0] = _salariesTransferAction;
    _transferActions[1] = _bonusesTransferAction;

    _actionsBuilder = simpleTransfersFactory.createSimpleTransfers(_transferActions);
  }

  function test_ExecuteTransaction() public {
    // Allow the CanonGuard to call the SimpleTransfers contract
    uint256 _approvalDuration = 1 days;

    vm.prank(address(SAFE_PROXY));
    canonGuard.approveActionsBuilder(_actionsBuilder, _approvalDuration);

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
    assertEq(USDC.balanceOf(_salariesDeposit), _safeBalance);
    assertEq(GRT.balanceOf(_bonusesPullSplit), _safeBalance);
    assertEq(USDC.balanceOf(address(SAFE_PROXY)), 0);
    assertEq(GRT.balanceOf(address(SAFE_PROXY)), 0);
  }
}
