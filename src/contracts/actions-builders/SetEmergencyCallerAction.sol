// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ActionBuilder} from 'contracts/actions-builders/ActionBuilder.sol';
import {IEmergencyModeHook} from 'interfaces/IEmergencyModeHook.sol';
import {ISetEmergencyCallerAction} from 'interfaces/actions-builders/ISetEmergencyCallerAction.sol';

contract SetEmergencyCallerAction is ISetEmergencyCallerAction, ActionBuilder {
  /// @inheritdoc ISetEmergencyCallerAction
  address public immutable CANON_GUARD;

  /// @inheritdoc ISetEmergencyCallerAction
  address public immutable EMERGENCY_CALLER;

  /**
   * @notice Constructor that sets up the SetEmergencyCallerAction contract
   * @param _parent The parent that deployed the action builder
   * @param _canonGuard The canon guard contract address that implements IEmergencyModeHook
   * @param _emergencyCaller The emergency caller address
   */
  constructor(address _parent, address _canonGuard, address _emergencyCaller) ActionBuilder(_parent) {
    CANON_GUARD = _canonGuard;
    EMERGENCY_CALLER = _emergencyCaller;
  }

  // ~~~ ACTIONS METHODS ~~~

  /// @inheritdoc ActionBuilder
  function getActions() external view override returns (Action[] memory _actions) {
    _actions = new Action[](1);
    _actions[0] = Action({
      target: CANON_GUARD,
      data: abi.encodeCall(IEmergencyModeHook.setEmergencyCaller, (EMERGENCY_CALLER)),
      value: 0
    });
  }
}
