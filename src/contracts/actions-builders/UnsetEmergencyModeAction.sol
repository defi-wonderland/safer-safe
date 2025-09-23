// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ActionsBuilder} from 'contracts/actions-builders/ActionsBuilder.sol';
import {IEmergencyModeHook} from 'interfaces/IEmergencyModeHook.sol';

contract UnsetEmergencyModeAction is ActionsBuilder {
  /**
   * @notice Given that the UnsetEmergencyModeAction has no parent, we set the parent to address(0)
   */
  constructor() ActionsBuilder(address(0)) {}

  // ~~~ ACTIONS METHODS ~~~

  /// @inheritdoc ActionsBuilder
  function getActions() external view override returns (Action[] memory _actions) {
    _actions = new Action[](1);
    _actions[0] =
      Action({target: msg.sender, data: abi.encodeCall(IEmergencyModeHook.unsetEmergencyMode, ()), value: 0});
  }
}
