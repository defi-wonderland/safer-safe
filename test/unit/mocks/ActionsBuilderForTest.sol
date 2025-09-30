// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ActionsBuilder} from 'src/contracts/actions-builders/ActionsBuilder.sol';

contract ActionsBuilderForTest is ActionsBuilder {
  constructor(address _parent) ActionsBuilder(_parent) {}

  function getActions() external pure override returns (Action[] memory _actions) {}
}
