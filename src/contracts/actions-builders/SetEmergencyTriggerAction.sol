// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IEmergencyModeHook} from 'interfaces/IEmergencyModeHook.sol';
import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';
import {ISetEmergencyTriggerAction} from 'interfaces/actions-builders/ISetEmergencyTriggerAction.sol';

contract SetEmergencyTriggerAction is ISetEmergencyTriggerAction {
  /// @inheritdoc ISetEmergencyTriggerAction
  address public immutable CANON_GUARD;

  /// @inheritdoc ISetEmergencyTriggerAction
  address public immutable EMERGENCY_TRIGGER;

  /**
   * @notice Constructor that sets up the SetEmergencyTriggerAction contract
   * @param _canonGuard The canon guard contract address that implements IEmergencyModeHook
   * @param _emergencyTrigger The emergency trigger address
   */
  constructor(address _canonGuard, address _emergencyTrigger) {
    CANON_GUARD = _canonGuard;
    EMERGENCY_TRIGGER = _emergencyTrigger;
  }

  // ~~~ ACTIONS METHODS ~~~

  /// @inheritdoc IActionsBuilder
  function getActions() external view returns (Action[] memory _actions) {
    _actions = new Action[](1);
    _actions[0] = Action({
      target: CANON_GUARD,
      data: abi.encodeCall(IEmergencyModeHook.setEmergencyTrigger, (EMERGENCY_TRIGGER)),
      value: 0
    });
  }
}
