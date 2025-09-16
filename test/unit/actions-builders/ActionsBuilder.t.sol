// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from 'forge-std/Test.sol';
import {ActionsBuilderForTest} from 'test/unit/mocks/ActionsBuilderForTest.sol';

contract UnitActionsBuilder is Test {
  ActionsBuilderForTest public actionsBuilder;
  address public parent = makeAddr('parent');

  function setUp() external {
    actionsBuilder = new ActionsBuilderForTest(parent);
  }

  function test_ConstructorWhenCalledByAChildContract() external view {
    // it sets the parent
    assertEq(actionsBuilder.PARENT(), parent);
  }

  function test_IS_BUILDERReturnsTrue() external view {
    // it returns true
    assertTrue(actionsBuilder.IS_BUILDER());
  }
}
