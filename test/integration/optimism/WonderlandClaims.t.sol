// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {OPxAction} from 'src/contracts/actions-builders/OPxAction.sol';
import {ISimpleActions} from 'src/interfaces/actions-builders/ISimpleActions.sol';
import {IntegrationOptimismBase} from 'test/integration/optimism/IntegrationOptimismBase.sol';

contract IntegrationWonderlandClaims is IntegrationOptimismBase {
  address internal _actionsBuilder;
  address internal _opxAction;

  address internal _opx = 0x1828Bff08BD244F7990edDCd9B19cc654b33cDB4;
  address internal _kiteVestingPlans = 0x1bb64AF7FE05fc69c740609267d2AbE3e119Ef82;
  address internal _wldVestingWallet = 0x5823c2D5cDB86547d10c312E7d3260603CdD085b;

  uint256 internal _claimableOP = 1_838_470_586_676_954_568_000;
  uint256 internal _claimableKITE = 1_026_331_380_010_145_208_370;
  uint256 internal _claimableWLD = 25_000 ether;

  function setUp() public override {
    super.setUp();

    uint256[] memory _plans = new uint256[](1);
    _plans[0] = 9;
    ISimpleActions.SimpleAction memory _claimKITE = ISimpleActions.SimpleAction({
      target: address(_kiteVestingPlans),
      signature: 'redeemPlans(uint256[])',
      data: abi.encode(_plans),
      value: 0
    });

    ISimpleActions.SimpleAction memory _claimWLD = ISimpleActions.SimpleAction({
      target: address(_wldVestingWallet),
      signature: 'release(address)',
      data: abi.encode(address(WLD)),
      value: 0
    });

    ISimpleActions.SimpleAction[] memory _simpleActions = new ISimpleActions.SimpleAction[](2);
    _simpleActions[0] = _claimKITE;
    _simpleActions[1] = _claimWLD;

    _actionsBuilder = simpleActionsFactory.createSimpleActions(_simpleActions);
    _opxAction = address(new OPxAction(_opx, address(SAFE_PROXY)));
  }

  function test_ExecuteTransaction() public {
    assertEq(KITE.balanceOf(address(SAFE_PROXY)), _safeBalance);
    assertEq(WLD.balanceOf(address(SAFE_PROXY)), _safeBalance);

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
    assertEq(KITE.balanceOf(address(SAFE_PROXY)), _claimableKITE + _safeBalance);
    assertEq(WLD.balanceOf(address(SAFE_PROXY)), _claimableWLD + _safeBalance);
  }

  function test_OPxDowngrade() public {
    assertEq(OP.balanceOf(address(SAFE_PROXY)), _safeBalance);

    // Allow the CanonGuard to call the contract
    uint256 _approvalDuration = 1 days;

    vm.prank(address(SAFE_PROXY));
    canonGuard.approveActionsBuilder(_opxAction, _approvalDuration);

    // Queue the transaction
    vm.prank(_safeOwners[0]);
    canonGuard.queueTransaction(_opxAction);

    // Wait for the timelock period
    vm.warp(block.timestamp + SHORT_TX_EXECUTION_DELAY);

    // Get the Safe transaction hash
    bytes32 _safeTxHash = canonGuard.getSafeTransactionHash(_opxAction);

    // Approve the Safe transaction hash
    for (uint256 _i; _i < _safeThreshold; ++_i) {
      vm.startPrank(_safeOwners[_i]);
      SAFE_PROXY.approveHash(_safeTxHash);
    }
    vm.stopPrank();

    // Execute the transaction
    canonGuard.executeTransaction(_opxAction);

    // Assert the token balances
    assertEq(OP.balanceOf(address(SAFE_PROXY)), _claimableOP + _safeBalance);
  }
}
