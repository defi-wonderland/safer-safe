// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from 'forge-std/Test.sol';
import {ActionsBuilderForTest} from 'test/unit/mocks/ActionsBuilderForTest.sol';

contract UnitActionsBuilderconstructor is Test {
  ActionsBuilderForTest public actionsBuilder;
  address public parent = makeAddr('parent');

  function setUp() external {
    actionsBuilder = new ActionsBuilderForTest(parent);
  }

  function test_WhenCalledByAChildContract() external view {
    // it sets the parent
    assertEq(actionsBuilder.PARENT(), parent);
  }
}
