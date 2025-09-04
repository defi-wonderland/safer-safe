// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from 'forge-std/Test.sol';
import {ActionBuilderForTest} from 'test/unit/mocks/ActionBuildForTest.sol';

contract UnitActionBuilderconstructor is Test {
  ActionBuilderForTest public actionBuilder;
  address public parent = makeAddr('parent');

  function setUp() external {
    actionBuilder = new ActionBuilderForTest(parent);
  }

  function test_WhenCalledByAChildContract() external view {
    // it sets the parent
    assertEq(actionBuilder.PARENT(), parent);
  }
}
