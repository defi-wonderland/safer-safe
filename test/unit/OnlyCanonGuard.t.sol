// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {OnlyCanonGuardForTest} from './mocks/OnlyCanonGuardForTest.sol';
import {Enum} from '@safe-smart-account/libraries/Enum.sol';
import {Test} from 'forge-std/Test.sol';
import {IOnlyCanonGuard} from 'interfaces/IOnlyCanonGuard.sol';

contract UnitOnlyCanonGuardcheckTransaction is Test {
  OnlyCanonGuardForTest public onlyCanonGuard;

  address public immutable MULTI_SEND_CALL_ONLY = makeAddr('MULTI_SEND_CALL_ONLY');

  function setUp() public {
    onlyCanonGuard = new OnlyCanonGuardForTest();
  }

  function test_WhenCallerIsCanonGuard() external view {
    // it allows transaction
    onlyCanonGuard.checkTransaction(
      MULTI_SEND_CALL_ONLY,
      0,
      '',
      Enum.Operation.DelegateCall,
      0,
      0,
      0,
      address(0),
      payable(address(0)),
      '',
      address(onlyCanonGuard) // msg.sender is canon guard
    );
  }

  function test_WhenCallerIsNotCanonGuard(address _randomSender) external {
    vm.assume(_randomSender != address(onlyCanonGuard));

    // it reverts with UnauthorizedSender
    vm.expectRevert(abi.encodeWithSelector(IOnlyCanonGuard.UnauthorizedSender.selector, _randomSender));
    onlyCanonGuard.checkTransaction(
      MULTI_SEND_CALL_ONLY,
      0,
      '',
      Enum.Operation.DelegateCall,
      0,
      0,
      0,
      address(0),
      payable(address(0)),
      '',
      _randomSender
    );
  }
}
