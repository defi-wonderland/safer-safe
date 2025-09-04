// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import {ActionHub} from 'src/contracts/action-hubs/ActionHub.sol';

contract ActionHubForTest is ActionHub {
  constructor(address _parent) ActionHub(_parent) {}

  function forTest_createNewActionBuilder(
    bytes memory _initCode,
    bytes32 _salt
  ) external returns (address _actionBuilder) {
    _actionBuilder = _createNewActionBuilder(_initCode, _salt);
  }

  function forTest_set__actionBuilders(address _actionBuilder, bool _exists) external {
    _actionBuilders[_actionBuilder] = _exists;
  }
}
