// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Factory} from 'src/contracts/factories/Factory.sol';

contract FactoryForTest is Factory {
  function createContract(address _contract) external {
    _children[_contract] = true;
  }
}
