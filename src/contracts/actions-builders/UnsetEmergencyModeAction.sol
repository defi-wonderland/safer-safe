// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IEmergencyModeHook} from 'interfaces/IEmergencyModeHook.sol';
import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';
import {IUnsetEmergencyModeAction} from 'interfaces/actions-builders/IUnsetEmergencyModeAction.sol';

contract UnsetEmergencyModeAction is IUnsetEmergencyModeAction {
  /// @inheritdoc IUnsetEmergencyModeAction
  address public immutable SAFE_ENTRYPOINT;

  /**
   * @notice Constructor that sets up the UnsetEmergencyModeAction contract
   * @param _safeEntrypoint The safe entrypoint contract address that implements IEmergencyModeHook
   */
  constructor(address _safeEntrypoint) {
    SAFE_ENTRYPOINT = _safeEntrypoint;
  }

  // ~~~ ACTIONS METHODS ~~~

  /// @inheritdoc IActionsBuilder
  function getActions() external view returns (Action[] memory _actions) {
    _actions = new Action[](1);
    _actions[0] =
      Action({target: SAFE_ENTRYPOINT, data: abi.encodeCall(IEmergencyModeHook.unsetEmergencyMode, ()), value: 0});
  }
}
