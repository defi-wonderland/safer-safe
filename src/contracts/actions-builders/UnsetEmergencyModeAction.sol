// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ActionsBuilder} from 'contracts/actions-builders/ActionsBuilder.sol';
import {IEmergencyModeHook} from 'interfaces/IEmergencyModeHook.sol';
import {IUnsetEmergencyModeAction} from 'interfaces/actions-builders/IUnsetEmergencyModeAction.sol';

contract UnsetEmergencyModeAction is IUnsetEmergencyModeAction, ActionsBuilder {
  /// @inheritdoc IUnsetEmergencyModeAction
  address public immutable CANON_GUARD;

  /**
   * @notice Constructor that sets up the UnsetEmergencyModeAction contract
   * @param _parent The parent that deployed the actions builder
   * @param _canonGuard The canon guard contract address that implements IEmergencyModeHook
   */
  constructor(address _parent, address _canonGuard) ActionsBuilder(_parent) {
    CANON_GUARD = _canonGuard;
  }

  // ~~~ ACTIONS METHODS ~~~

  /// @inheritdoc ActionsBuilder
  function getActions() external view override returns (Action[] memory _actions) {
    _actions = new Action[](1);
    _actions[0] =
      Action({target: CANON_GUARD, data: abi.encodeCall(IEmergencyModeHook.unsetEmergencyMode, ()), value: 0});
  }
}
