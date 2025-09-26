// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IActionHubChild} from 'interfaces/action-hubs/IActionHubChild.sol';

abstract contract ActionHubChild is IActionHubChild {
  /// @inheritdoc IActionHubChild
  address public immutable HUB;

  /**
   * @notice Constructor that sets up hub child
   * @param _hub The hub address
   */
  constructor(address _hub) {
    HUB = _hub;
  }
}
