// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from 'forge-std/Test.sol';
import {IActionHub} from 'interfaces/action-hubs/IActionHub.sol';
import {CREATE3} from 'solady/utils/CREATE3.sol';
import {CappedTokenTransfers} from 'src/contracts/actions-builders/CappedTokenTransfers.sol';
import {ActionHubForTest} from 'test/unit/mocks/ActionHubForTest.sol';

contract UnitActionHub is Test {
  ActionHubForTest public actionHub;
  address public parent = makeAddr('parent');

  function setUp() public {
    actionHub = new ActionHubForTest(parent);
  }

  function test_ConstructorWhenCalledByAChildContract() external view {
    // it sets the parent
    assertEq(actionHub.PARENT(), parent);
  }

  function test_IsChildWhenTheActionsBuilderIsAChild(address _actionsBuilder) external {
    actionHub.forTest_set__actionsBuilders(_actionsBuilder, true);

    // it returns true
    assertTrue(actionHub.isChild(_actionsBuilder));
  }

  function test_IsChildWhenTheActionsBuilderIsNotAChild(address _actionsBuilder) external {
    actionHub.forTest_set__actionsBuilders(_actionsBuilder, false);

    // it returns false
    assertFalse(actionHub.isChild(_actionsBuilder));
  }

  function test__createNewActionsBuilderWhenCalled(
    bytes32 _salt,
    address _token,
    uint256 _amount,
    address _recipient
  ) external {
    bytes memory _initCode = abi.encodePacked(
      type(CappedTokenTransfers).creationCode,
      abi.encode(address(actionHub), _token, _amount, _recipient, address(this))
    );

    address _expectedActionsBuilder = CREATE3.predictDeterministicAddress(_salt, address(actionHub));

    // it emits a NewActionsBuilderCreated event
    vm.expectEmit();
    emit IActionHub.NewActionsBuilderCreated(_expectedActionsBuilder, _initCode, _salt);

    address _actionsBuilder = actionHub.forTest_createNewActionsBuilder(_initCode, _salt);

    // it creates a new actions builder
    assertEq(_actionsBuilder, _expectedActionsBuilder);
    // it marks the actions builder as a child
    assertTrue(actionHub.isChild(_actionsBuilder));
  }
}
