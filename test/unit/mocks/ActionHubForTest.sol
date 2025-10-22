// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ActionHub} from 'src/contracts/action-hubs/ActionHub.sol';

contract ActionHubForTest is ActionHub {
  constructor(address _parent) ActionHub(_parent) {}

  function forTest_saveNewActionsBuilder(address _actionsBuilder) external {
    _saveNewActionsBuilder(_actionsBuilder);
  }

  function forTest_set__actionsBuilders(address _actionsBuilder, bool _exists) external {
    _actionsBuilders[_actionsBuilder] = _exists;
  }
}
