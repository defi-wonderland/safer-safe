// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import {EmergencyModeHookForTest} from './mocks/EmergencyModeHookForTest.sol';
import {Test} from 'forge-std/Test.sol';
import {IEmergencyModeHook} from 'src/interfaces/IEmergencyModeHook.sol';
import {ISafeManageable} from 'src/interfaces/ISafeManageable.sol';

contract UnitEmergencyModeHook is Test {
  EmergencyModeHookForTest public emergencyModeHook;
  address public emergencyTrigger = makeAddr('emergencyTrigger');
  address public emergencyCaller = makeAddr('emergencyCaller');
  address public safe = makeAddr('safe');

  function setUp() public {
    emergencyModeHook = new EmergencyModeHookForTest(emergencyTrigger, emergencyCaller, safe);
  }

  function test_ConstructorWhenEmergencyTriggerIsZeroAddress() external {
    // It reverts with ZeroAddress
    vm.expectRevert(abi.encodeWithSelector(IEmergencyModeHook.ZeroAddress.selector));
    new EmergencyModeHookForTest(address(0), emergencyCaller, safe);
  }

  function test_ConstructorWhenEmergencyCallerIsZeroAddress() external {
    // It reverts with ZeroAddress
    vm.expectRevert(abi.encodeWithSelector(IEmergencyModeHook.ZeroAddress.selector));
    new EmergencyModeHookForTest(emergencyTrigger, address(0), safe);
  }

  function test_ConstructorWhenEmergencyTriggerAndEmergencyCallerAreNotZeroAddress(
    address _emergencyTrigger,
    address _emergencyCaller
  ) external {
    vm.assume(_emergencyTrigger != address(0));
    vm.assume(_emergencyCaller != address(0));

    emergencyModeHook = new EmergencyModeHookForTest(_emergencyTrigger, _emergencyCaller, safe);

    // It sets emergencyTrigger to the given value
    assertEq(emergencyModeHook.emergencyTrigger(), _emergencyTrigger);
    // It sets emergencyCaller to the given value
    assertEq(emergencyModeHook.emergencyCaller(), _emergencyCaller);
  }

  function test_SetEmergencyModeWhenSenderIsNotEmergencyTrigger(address _sender) external {
    vm.assume(_sender != emergencyModeHook.emergencyTrigger());

    // It reverts with Unauthorized
    vm.expectRevert(
      abi.encodeWithSelector(IEmergencyModeHook.Unauthorized.selector, _sender, emergencyModeHook.emergencyTrigger())
    );
    vm.prank(_sender);
    emergencyModeHook.setEmergencyMode();
  }

  function test_SetEmergencyModeWhenSenderIsEmergencyTrigger() external {
    vm.prank(emergencyModeHook.emergencyTrigger());
    emergencyModeHook.setEmergencyMode();

    // It sets emergencyMode to true
    assertTrue(emergencyModeHook.emergencyMode());
  }

  function test_UnsetEmergencyModeWhenSenderIsSafe() external {
    vm.prank(safe);
    emergencyModeHook.unsetEmergencyMode();

    // It sets emergencyMode to false
    assertFalse(emergencyModeHook.emergencyMode());
  }

  function test_UnsetEmergencyModeWhenSenderIsNotSafe(address _sender) external {
    vm.assume(_sender != safe);

    // It reverts
    vm.expectRevert(abi.encodeWithSelector(ISafeManageable.NotSafe.selector));
    vm.prank(_sender);
    emergencyModeHook.unsetEmergencyMode();
  }

  modifier whenSenderIsSafe() {
    vm.startPrank(safe);
    _;
    vm.stopPrank();
  }

  function test_SetEmergencyCallerWhenEmergencyCallerIsZeroAddress() external whenSenderIsSafe {
    // It reverts with ZeroAddress
    vm.expectRevert(abi.encodeWithSelector(IEmergencyModeHook.ZeroAddress.selector));
    emergencyModeHook.setEmergencyCaller(address(0));
  }

  function test_SetEmergencyCallerWhenEmergencyCallerIsNotZeroAddress(address _emergencyCaller)
    external
    whenSenderIsSafe
  {
    vm.assume(_emergencyCaller != address(0));

    // It sets emergencyCaller to the given value
    emergencyModeHook.setEmergencyCaller(_emergencyCaller);
    assertEq(emergencyModeHook.emergencyCaller(), _emergencyCaller);
  }

  function test_SetEmergencyCallerWhenSenderIsNotSafe(address _sender) external {
    vm.assume(_sender != safe);

    // It reverts
    vm.expectRevert(abi.encodeWithSelector(ISafeManageable.NotSafe.selector));
    vm.prank(_sender);
    emergencyModeHook.setEmergencyCaller(address(0));
  }

  function test_SetEmergencyTriggerWhenEmergencyTriggerIsZeroAddress() external whenSenderIsSafe {
    // It reverts with ZeroAddress
    vm.expectRevert(abi.encodeWithSelector(IEmergencyModeHook.ZeroAddress.selector));
    emergencyModeHook.setEmergencyTrigger(address(0));
  }

  function test_SetEmergencyTriggerWhenEmergencyTriggerIsNotZeroAddress(address _emergencyTrigger)
    external
    whenSenderIsSafe
  {
    vm.assume(_emergencyTrigger != address(0));

    // It sets emergencyTrigger to the given value
    emergencyModeHook.setEmergencyTrigger(_emergencyTrigger);
    assertEq(emergencyModeHook.emergencyTrigger(), _emergencyTrigger);
  }

  function test_SetEmergencyTriggerWhenSenderIsNotSafe(address _sender) external {
    vm.assume(_sender != safe);

    // It reverts
    vm.expectRevert(abi.encodeWithSelector(ISafeManageable.NotSafe.selector));
    vm.prank(_sender);
    emergencyModeHook.setEmergencyTrigger(address(0));
  }

  modifier whenEmergencyModeIsTrue() {
    vm.prank(emergencyModeHook.emergencyTrigger());
    emergencyModeHook.setEmergencyMode();
    _;
  }

  function test__onBeforeExecutionWhenSenderIsNotEmergencyCaller(address _sender) external whenEmergencyModeIsTrue {
    vm.assume(_sender != emergencyModeHook.emergencyCaller());

    // It reverts with Unauthorized
    vm.expectRevert(
      abi.encodeWithSelector(IEmergencyModeHook.Unauthorized.selector, _sender, emergencyModeHook.emergencyCaller())
    );
    vm.prank(_sender);
    emergencyModeHook.forTest_onBeforeExecution();
  }

  function test__onBeforeExecutionWhenSenderIsEmergencyCaller() external whenEmergencyModeIsTrue {
    // It does not revert
    vm.prank(emergencyModeHook.emergencyCaller());
    emergencyModeHook.forTest_onBeforeExecution();
  }

  function test__onBeforeExecutionWhenEmergencyModeIsFalse() external {
    // It sets emergencyMode to false
    vm.prank(safe);
    emergencyModeHook.unsetEmergencyMode();

    // It does not revert
    vm.prank(emergencyModeHook.emergencyCaller());
    emergencyModeHook.forTest_onBeforeExecution();
  }
}
