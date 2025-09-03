// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Factory} from 'contracts/factories/Factory.sol';
import {Test} from 'forge-std/Test.sol';

contract UnitFactoryisChild is Test {
  Factory public factory;

  function setUp() external {
    factory = new Factory();
  }

  function test_WhenTheContractIsCreatedByTheFactory(address _contract) external {
    vm.store(address(factory), keccak256(abi.encode(_contract, 0)), bytes32(uint256(1)));

    // it returns true
    assertTrue(factory.isChild(_contract));
  }

  function test_WhenTheContractIsNotCreatedByTheFactory(address _contract) external view {
    // it returns false
    assertFalse(factory.isChild(_contract));
  }
}
