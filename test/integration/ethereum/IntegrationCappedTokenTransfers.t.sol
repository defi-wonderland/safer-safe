// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {CappedTokenTransfersHub} from 'src/contracts/action-hubs/CappedTokenTransfersHub.sol';

import {ICappedTokenTransfersHub} from 'src/interfaces/action-hubs/ICappedTokenTransfersHub.sol';
import {ICappedTokenTransfers} from 'src/interfaces/actions-builders/ICappedTokenTransfers.sol';
import {IntegrationEthereumBase} from 'test/integration/ethereum/IntegrationEthereumBase.sol';

contract IntegrationCappedTokenTransfers is IntegrationEthereumBase {
  ICappedTokenTransfersHub internal _cappedTokenTransfersHub;
  address internal _recipient;

  function setUp() public override {
    super.setUp();

    _recipient = makeAddr('recipient');

    address[] memory _tokens = new address[](2);
    _tokens[0] = address(WETH);
    _tokens[1] = address(GRT);

    uint256[] memory _caps = new uint256[](2);
    _caps[0] = 100 ether;
    _caps[1] = 200 ether;

    // Deploy the CappedTokenTransfersHub
    _cappedTokenTransfersHub = new CappedTokenTransfersHub(address(SAFE_PROXY), _recipient, _tokens, _caps, 7 days);
  }

  function test_CreateNewActionBuilder() public {
    // Create the new action builder
    vm.prank(_safeOwners[0]);
    address _actionsBuilder = _cappedTokenTransfersHub.createNewActionBuilder(address(WETH), 10 ether);

    // Check that the action builder was created correctly
    assertTrue(_cappedTokenTransfersHub.isChild(_actionsBuilder));
    assertEq(ICappedTokenTransfers(_actionsBuilder).TOKEN(), address(WETH));
    assertEq(ICappedTokenTransfers(_actionsBuilder).AMOUNT(), 10 ether);
    assertEq(ICappedTokenTransfers(_actionsBuilder).RECIPIENT(), _recipient);
    assertEq(ICappedTokenTransfers(_actionsBuilder).HUB(), address(_cappedTokenTransfersHub));
  }

  function test_TransferSuccessfully() public {
    // Create the new action builder
    vm.prank(_safeOwners[0]);
    address _actionsBuilder = _cappedTokenTransfersHub.createNewActionBuilder(address(WETH), _safeBalance);

    // Allow the CanonGuard to call the contract
    uint256 _approvalDuration = 1 days;

    vm.prank(address(SAFE_PROXY));
    canonGuard.approveActionsBuilder(address(_cappedTokenTransfersHub), _approvalDuration);

    // Queue the transaction
    vm.prank(_safeOwners[0]);
    canonGuard.queueHubTransaction(address(_cappedTokenTransfersHub), _actionsBuilder);

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
    assertEq(WETH.balanceOf(_recipient), _safeBalance);
    assertEq(WETH.balanceOf(address(SAFE_PROXY)), 0);
  }

  function test_TransferUnsuccessfully() public {
    // Create the new action builder
    vm.prank(_safeOwners[0]);
    address _actionsBuilder = _cappedTokenTransfersHub.createNewActionBuilder(address(WETH), 1000 ether);

    // Allow the CanonGuard to call the contract
    uint256 _approvalDuration = 1 days;

    vm.prank(address(SAFE_PROXY));
    canonGuard.approveActionsBuilder(address(_cappedTokenTransfersHub), _approvalDuration);

    // Queue the transaction
    vm.prank(_safeOwners[0]);
    canonGuard.queueHubTransaction(address(_cappedTokenTransfersHub), _actionsBuilder);

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
    vm.expectRevert('GS013'); // tx does revert with CapExceeded(), but the revert is catched by the safe
    canonGuard.executeTransaction(_actionsBuilder);

    // Assert the token balances
    assertEq(WETH.balanceOf(_recipient), 0);
    assertEq(WETH.balanceOf(address(SAFE_PROXY)), _safeBalance);
  }
}
