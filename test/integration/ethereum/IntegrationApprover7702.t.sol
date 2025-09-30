// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ISimpleTransfers} from 'interfaces/actions-builders/ISimpleTransfers.sol';
import {Approver} from 'src/contracts/Approver.sol';
import {IntegrationEthereumBase} from 'test/integration/ethereum/IntegrationEthereumBase.sol';

contract IntegrationApprover7702 is IntegrationEthereumBase {
  address public aliceAddress;
  uint256 public alicePk;

  address internal _approverImplementation;
  address internal _actionsBuilder;

  address internal _salariesDeposit = 0xa7242329Fa88d501f2D2Abe7d63FFC8C5dA38A99;

  function setUp() public override {
    super.setUp();

    (aliceAddress, alicePk) = makeAddrAndKey('alice');

    // Deploy Approver implementation
    _approverImplementation = address(new Approver(address(canonGuard)));

    // Deploy the SimpleTransfers contract
    ISimpleTransfers.TransferAction memory _salariesTransferAction =
      ISimpleTransfers.TransferAction({token: address(USDC), to: _salariesDeposit, amount: _safeBalance});
    ISimpleTransfers.TransferAction[] memory _transferActions = new ISimpleTransfers.TransferAction[](1);
    _transferActions[0] = _salariesTransferAction;
    _actionsBuilder = simpleTransfersFactory.createSimpleTransfers(_transferActions);

    // Add ALICE as a Safe owner, reduce the threshold to 1
    vm.startPrank(address(SAFE_PROXY));
    SAFE_PROXY.addOwnerWithThreshold(aliceAddress, 1);
    vm.stopPrank();
  }

  function test_Approver() public {
    // Allow the CanonGuard to call the SimpleTransfers contract
    uint256 _approvalDuration = 1 days;

    vm.prank(address(SAFE_PROXY));
    canonGuard.approveActionsBuilderOrHub(_actionsBuilder, _approvalDuration);

    // Queue the transaction
    vm.prank(_safeOwners[0]);
    canonGuard.queueTransaction(_actionsBuilder);

    // Wait for the timelock period
    vm.warp(block.timestamp + SHORT_TX_EXECUTION_DELAY);

    // Alice signs a delegation allowing `implementation` to execute transactions on her behalf.
    vm.signAndAttachDelegation(_approverImplementation, alicePk);

    // Verify that Alice's account now behaves as a smart contract.
    bytes memory code = address(aliceAddress).code;
    assertNotEq(code.length, 0);

    // Execute approveTx()
    vm.startPrank(aliceAddress);
    Approver(aliceAddress).approveTx(address(_actionsBuilder), SAFE_PROXY.nonce());
    vm.stopPrank();

    // Execute the transaction
    canonGuard.executeTransaction(_actionsBuilder);

    // Assert the token balances
    assertEq(USDC.balanceOf(_salariesDeposit), _safeBalance);
    assertEq(USDC.balanceOf(address(SAFE_PROXY)), 0);
  }
}
