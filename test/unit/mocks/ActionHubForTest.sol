// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ActionHub} from 'src/contracts/action-hubs/ActionHub.sol';

contract ActionHubForTest is ActionHub {
  constructor(address _parent) ActionHub(_parent) {}

  function forTest_createNewActionsBuilder(
    bytes memory _initCode,
    bytes32 _salt
  ) external returns (address _actionsBuilder) {
    _actionsBuilder = _createNewActionsBuilder(_initCode, _salt);
  }

  function forTest_set__actionsBuilders(address _actionsBuilder, bool _exists) external {
    _actionsBuilders[_actionsBuilder] = _exists;
  }
}
