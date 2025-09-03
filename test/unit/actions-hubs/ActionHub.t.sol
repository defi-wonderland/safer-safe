// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import {Test} from 'forge-std/Test.sol';
import {IActionHub} from 'interfaces/action-hubs/IActionHub.sol';
import {CREATE3} from 'solady/utils/CREATE3.sol';
import {CappedTokenTransfers} from 'src/contracts/actions-builders/CappedTokenTransfers.sol';
import {ActionHubForTest} from 'test/unit/mocks/ActionHubForTest.sol';

contract UnitActionHub is Test {
  ActionHubForTest public actionHub;

  function setUp() public {
    actionHub = new ActionHubForTest();
  }

  function test_IsChildWhenTheActionBuilderIsAChild(address _actionBuilder) external {
    actionHub.forTest_set__actionBuilders(_actionBuilder, true);

    // it returns true
    assertTrue(actionHub.isChild(_actionBuilder));
  }

  function test_IsChildWhenTheActionBuilderIsNotAChild(address _actionBuilder) external {
    actionHub.forTest_set__actionBuilders(_actionBuilder, false);

    // it returns false
    assertFalse(actionHub.isChild(_actionBuilder));
  }

  function test__createNewActionBuilderWhenCalled(
    bytes32 _salt,
    address _token,
    uint256 _amount,
    address _recipient
  ) external {
    bytes memory _initCode = abi.encodePacked(
      type(CappedTokenTransfers).creationCode,
      abi.encode(address(actionHub), _token, _amount, _recipient, address(this))
    );

    address _expectedActionBuilder = CREATE3.predictDeterministicAddress(_salt, address(actionHub));

    // it emits a NewActionBuilderCreated event
    vm.expectEmit();
    emit IActionHub.NewActionBuilderCreated(_expectedActionBuilder, _initCode, _salt);

    address _actionBuilder = actionHub.forTest_createNewActionBuilder(_initCode, _salt);

    // it creates a new action builder
    assertEq(_actionBuilder, _expectedActionBuilder);
    // it marks the action builder as a child
    assertTrue(actionHub.isChild(_actionBuilder));
  }
}
