// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from 'forge-std/Test.sol';
import {ActionHubForTest} from 'test/unit/mocks/ActionHubForTest.sol';

contract UnitActionHub is Test {
  ActionHubForTest public actionHub;
  address public parent = makeAddr('parent');

  function setUp() public {
    actionHub = new ActionHubForTest(parent);
  }

  function test_Constructor_WhenCalledByAChildContract() external view {
    // it sets the parent
    assertEq(actionHub.PARENT(), parent);
  }

  function test_IsHubChild_WhenTheActionsBuilderIsAChild(address _actionsBuilder) external {
    actionHub.forTest_set__actionsBuilders(_actionsBuilder, true);

    // it returns true
    assertTrue(actionHub.isHubChild(_actionsBuilder));
  }

  function test_IsHubChild_WhenTheActionsBuilderIsNotAChild(address _actionsBuilder) external {
    actionHub.forTest_set__actionsBuilders(_actionsBuilder, false);

    // it returns false
    assertFalse(actionHub.isHubChild(_actionsBuilder));
  }

  function test__saveNewActionsBuilder_WhenCalled(address _actionsBuilder) external {
    actionHub.forTest_saveNewActionsBuilder(_actionsBuilder);

    // it marks the actions builder as a child
    assertTrue(actionHub.isHubChild(_actionsBuilder));
  }
}
