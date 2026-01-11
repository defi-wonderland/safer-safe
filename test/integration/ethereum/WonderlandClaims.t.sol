// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IArbitraryActions} from 'src/interfaces/actions-builders/IArbitraryActions.sol';
import {IntegrationEthereumBase} from 'test/integration/ethereum/IntegrationEthereumBase.sol';

contract IntegrationWonderlandClaims is IntegrationEthereumBase {
  address internal _actionsBuilder;

  address internal _gtcSimpleEscrow = 0x7DAE0a882bd4511fa6918e6A35B21aD31a89E3Ab;
  address internal _balSimpleEscrow = 0xD6208F3B61640baEbb71aa59b58Cc61E32F8Ddf5;
  address internal _kp3rSimpleEscrow = 0x164A0619E3C18023fbbCBBB5ab8f332F389Eb731;

  uint256 internal _claimableGTC = 37_451_341_324_200_913_242_010;

  function setUp() public override {
    super.setUp();

    // Deploy the ArbitraryActions contract
    IArbitraryActions.ArbitraryAction memory _claimGTC =
      IArbitraryActions.ArbitraryAction({target: address(_gtcSimpleEscrow), signature: 'claim()', data: '', value: 0});

    IArbitraryActions.ArbitraryAction memory _claimBAL =
      IArbitraryActions.ArbitraryAction({target: address(_balSimpleEscrow), signature: 'claim()', data: '', value: 0});

    IArbitraryActions.ArbitraryAction memory _claimKP3R =
      IArbitraryActions.ArbitraryAction({target: address(_kp3rSimpleEscrow), signature: 'claim()', data: '', value: 0});

    IArbitraryActions.ArbitraryAction[] memory _arbitraryActions = new IArbitraryActions.ArbitraryAction[](3);
    _arbitraryActions[0] = _claimGTC;
    _arbitraryActions[1] = _claimBAL;
    _arbitraryActions[2] = _claimKP3R;

    _actionsBuilder = arbitraryActionsFactory.createArbitraryActions(_arbitraryActions);
  }

  function test_ExecuteTransaction() public {
    assertEq(GTC.balanceOf(address(SAFE_PROXY)), _safeBalance);
    assertEq(BAL.balanceOf(address(SAFE_PROXY)), _safeBalance);
    assertEq(KP3R.balanceOf(address(SAFE_PROXY)), _safeBalance);

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

    // Assert the token balances (only GTC increased)
    assertEq(GTC.balanceOf(address(SAFE_PROXY)), _claimableGTC + _safeBalance);
    assertEq(BAL.balanceOf(address(SAFE_PROXY)), _safeBalance);
    assertEq(KP3R.balanceOf(address(SAFE_PROXY)), _safeBalance);
  }
}
