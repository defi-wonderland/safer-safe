// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {EverclearTokenStake} from 'src/contracts/actions-builders/EverclearTokenStake.sol';
import {IEverclearTokenStake} from 'src/interfaces/actions-builders/IEverclearTokenStake.sol';
import {IntegrationEthereumBase} from 'test/integration/ethereum/IntegrationEthereumBase.sol';

contract IntegrationEverclearStakes is IntegrationEthereumBase {
  // ~~~ ACTIONS ~~~
  address internal _actionsBuilder;
  address internal _vestingEscrow = 0xbf6c61d8f4D16Ed61D38b895ffb76D3107852b99;
  address internal _vestingWallet = 0xab47c5bB2DbdCaB2d8B41f083f692e608439e03f;
  address internal _spokeBridge = 0x420148270e6144cF761eFCD184F3B7FBF034977f;
  address internal _clearLockbox = 0x22f424Bca11FE154c403c277b5F8dAb54a4bA29b;
  address internal _next = 0xFE67A4450907459c3e1FFf623aA927dD4e28c67a;
  address internal _clear = 0x58b9cB810A68a7f3e1E4f8Cb45D1B9B3c79705E8;
  uint256 internal _lockTime = 24 * 30 days;

  uint256 internal _nextDust = 2_631_136_986_301_369_863_014;

  function setUp() public override {
    super.setUp();

    // Deploy the contract
    _actionsBuilder = address(
      new EverclearTokenStake(
        address(0), _vestingEscrow, _vestingWallet, _spokeBridge, _clearLockbox, _next, _clear, _lockTime
      )
    );
  }

  function test_ExecuteTransaction() public {
    assertEq(NEXT.balanceOf(address(SAFE_PROXY)), _safeBalance);
    assertEq(CLEAR.balanceOf(address(SAFE_PROXY)), _safeBalance);

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
    assertEq(CLEAR.balanceOf(address(SAFE_PROXY)), _safeBalance);
    assertEq(IEverclearTokenStake(_actionsBuilder).VESTING_ESCROW().unclaimed(), 0);
    assertEq(IEverclearTokenStake(_actionsBuilder).VESTING_WALLET().releasable(), 0);
    // NOTE: given that the tx was executed in a later block, some dust may have been added to the balance
    assertEq(NEXT.balanceOf(address(SAFE_PROXY)), _nextDust);
  }
}
