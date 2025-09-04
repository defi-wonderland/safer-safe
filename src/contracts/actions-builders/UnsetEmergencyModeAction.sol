// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IEmergencyModeHook} from 'interfaces/IEmergencyModeHook.sol';
import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';
import {IUnsetEmergencyModeAction} from 'interfaces/actions-builders/IUnsetEmergencyModeAction.sol';

contract UnsetEmergencyModeAction is IUnsetEmergencyModeAction {
  /// @inheritdoc IUnsetEmergencyModeAction
  address public immutable CANON_GUARD;

  /**
   * @notice Constructor that sets up the UnsetEmergencyModeAction contract
   * @param _canonGuard The canon guard contract address that implements IEmergencyModeHook
   */
  constructor(address _canonGuard) {
    CANON_GUARD = _canonGuard;
  }

  // ~~~ ACTIONS METHODS ~~~

  /// @inheritdoc IActionsBuilder
  function getActions() external view returns (Action[] memory _actions) {
    _actions = new Action[](1);
    _actions[0] =
      Action({target: CANON_GUARD, data: abi.encodeCall(IEmergencyModeHook.unsetEmergencyMode, ()), value: 0});
  }
}
