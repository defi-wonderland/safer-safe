// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from 'forge-std/Test.sol';
import {FactoryForTest} from 'test/unit/mocks/FactoryForTest.sol';

contract UnitFactoryisChild is Test {
  FactoryForTest public factory;

  function setUp() external {
    factory = new FactoryForTest();
  }

  function test_WhenTheContractIsCreatedByTheFactory(address _contract) external {
    factory.createContract(_contract);
    // it returns true
    assertTrue(factory.isChild(_contract));
  }

  function test_WhenTheContractIsNotCreatedByTheFactory(address _contract) external view {
    // it returns false
    assertFalse(factory.isChild(_contract));
  }
}
