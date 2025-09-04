// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ActionBuilder} from 'src/contracts/actions-builders/ActionBuilder.sol';

contract ActionBuilderForTest is ActionBuilder {
  constructor(address _parent) ActionBuilder(_parent) {}

  function getActions() external pure override returns (Action[] memory _actions) {}
}
