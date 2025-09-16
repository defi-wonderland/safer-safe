// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ActionsBuilder} from 'contracts/actions-builders/ActionsBuilder.sol';
import {IEmergencyModeHook} from 'interfaces/IEmergencyModeHook.sol';
import {ISetEmergencyTriggerAction} from 'interfaces/actions-builders/ISetEmergencyTriggerAction.sol';

/**
 * @title SetEmergencyTriggerAction
 * @notice Contract that builds an action to set the emergency trigger
 * @notice The emergency trigger is the address that can set the emergency mode
 * @dev Builds an action that calls IEmergencyModeHook.setEmergencyTrigger
 */
contract SetEmergencyTriggerAction is ISetEmergencyTriggerAction, ActionsBuilder {
  /// @inheritdoc ISetEmergencyTriggerAction
  address public immutable CANON_GUARD;

  /// @inheritdoc ISetEmergencyTriggerAction
  address public immutable EMERGENCY_TRIGGER;

  /**
   * @notice Constructor that sets up the SetEmergencyTriggerAction contract
   * @param _parent The parent that deployed the actions builder
   * @param _canonGuard The canon guard contract address that implements IEmergencyModeHook
   * @param _emergencyTrigger The emergency trigger address. This is the address that can set the emergency mode
   */
  constructor(address _parent, address _canonGuard, address _emergencyTrigger) ActionsBuilder(_parent) {
    CANON_GUARD = _canonGuard;
    EMERGENCY_TRIGGER = _emergencyTrigger;
  }

  // ~~~ ACTIONS METHODS ~~~

  /// @inheritdoc ActionsBuilder
  function getActions() external view override returns (Action[] memory _actions) {
    _actions = new Action[](1);
    _actions[0] = Action({
      target: CANON_GUARD,
      data: abi.encodeCall(IEmergencyModeHook.setEmergencyTrigger, (EMERGENCY_TRIGGER)),
      value: 0
    });
  }
}
