// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {SafeManageableForTest} from './mocks/SafeManageableForTest.sol';
import {IOwnerManager} from '@safe-smart-account/interfaces/IOwnerManager.sol';
import {Test} from 'forge-std/Test.sol';
import {ISafeManageable} from 'interfaces/ISafeManageable.sol';

contract UnitSafeManageable is Test {
  SafeManageableForTest public safeManageable;

  address public immutable SAFE = makeAddr('SAFE');

  function setUp() public {
    safeManageable = new SafeManageableForTest(SAFE);
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

  function test_ConstructorWhenPassingValidParameters(address _safe) external {
    _assumeFuzzable(_safe);
    SafeManageableForTest newSafeManageable = new SafeManageableForTest(_safe);
    assertEq(address(ISafeManageable(address(newSafeManageable)).SAFE()), _safe);
  }

  modifier whenCallerIsSafe() {
    // No need to mock anything, just prank as SAFE
    _;
  }

  function test_IsSafeWhenCallerIsSafe() external whenCallerIsSafe {
    vm.prank(SAFE);
    safeManageable.testIsSafeModifier();
  }

  function test_IsSafeWhenCallerIsNotSafe(address _caller) external {
    vm.assume(_caller != SAFE);
    vm.expectRevert(ISafeManageable.NotSafe.selector);
    vm.prank(_caller);
    safeManageable.testIsSafeModifier();
  }

  modifier whenCallerIsSafeOwner() {
    _mockAndExpect(SAFE, abi.encodeWithSelector(IOwnerManager.isOwner.selector), abi.encode(true));
    _;
  }

  function test_IsSafeOwnerWhenCallerIsSafeOwner() external whenCallerIsSafeOwner {
    vm.prank(SAFE);
    safeManageable.testIsSafeOwnerModifier();
  }

  function test_IsSafeOwnerWhenCallerIsNotSafeOwner(address _caller) external {
    vm.assume(_caller != SAFE);
    _mockAndExpect(SAFE, abi.encodeWithSelector(IOwnerManager.isOwner.selector), abi.encode(false));
    vm.expectRevert(ISafeManageable.NotSafeOwner.selector);
    vm.prank(_caller);
    safeManageable.testIsSafeOwnerModifier();
  }
}
