// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import {ISafe} from '@safe-smart-account/interfaces/ISafe.sol';
import {Test} from 'forge-std/Test.sol';
import {Approver} from 'src/contracts/Approver.sol';
import {IApprover} from 'src/interfaces/IApprover.sol';
import {ISafeManageable} from 'src/interfaces/ISafeManageable.sol';

contract UnitApprover is Test {
  address public canonGuard;
  address public safe;
  Approver public approver;

  function setUp() external {
    canonGuard = makeAddr('canonGuard');
    safe = makeAddr('safe');

    _mockAndExpect(canonGuard, abi.encodeWithSelector(ISafeManageable.SAFE.selector), abi.encode(ISafe(safe)));

    approver = new Approver(canonGuard);
  }

  function test_ConstructorWhenCalled(address _canonGuard, address _safe) external {
    _assumeFuzzable(_canonGuard);
    _assumeFuzzable(_safe);

    _mockAndExpect(_canonGuard, abi.encodeWithSelector(ISafeManageable.SAFE.selector), abi.encode(ISafe(_safe)));

    approver = new Approver(_canonGuard);

    // it sets the canonGuard
    assertEq(address(approver.CANON_GUARD()), _canonGuard);
    // it sets the safe
    assertEq(address(approver.SAFE()), _safe);
  }

  function test_ApproveTxWhenCalledByTheItself(
    address _actionBuilder,
    uint256 _safeNonce,
    bytes32 _safeTxHash
  ) external {
    // it gets the safe tx hash
    _mockAndExpect(
      canonGuard,
      abi.encodeWithSignature('getSafeTransactionHash(address,uint256)', _actionBuilder, _safeNonce),
      abi.encode(_safeTxHash)
    );

    // it approves the safe transaction hash
    _mockAndExpect(safe, abi.encodeWithSelector(ISafe.approveHash.selector, _safeTxHash), abi.encode(true));

    // it emits the tx approved event
    vm.expectEmit();
    emit IApprover.TxApproved(_actionBuilder, _safeNonce, _safeTxHash);

    vm.prank(address(approver));
    approver.approveTx(_actionBuilder, _safeNonce);
  }

  function test_ApproveTxWhenCalledByANon_itself(address _actionBuilder, uint256 _safeNonce) external {
    // it reverts with InvalidSender
    vm.expectRevert(abi.encodeWithSelector(IApprover.InvalidSender.selector));
    approver.approveTx(_actionBuilder, _safeNonce);
  }

  function _mockAndExpect(address _target, bytes memory _call, bytes memory _returnData) internal {
    vm.mockCall(_target, _call, _returnData);
    vm.expectCall(_target, _call);
  }

  function _assumeFuzzable(address _address) internal pure {
    assumeNotForgeAddress(_address);
    assumeNotZeroAddress(_address);
    assumeNotPrecompile(_address);
  }
}
