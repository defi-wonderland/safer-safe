// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IEmergencyModeHook} from 'interfaces/IEmergencyModeHook.sol';
import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';
import {ISetEmergencyTriggerAction} from 'interfaces/actions-builders/ISetEmergencyTriggerAction.sol';

contract SetEmergencyTriggerAction is ISetEmergencyTriggerAction {
  /// @inheritdoc ISetEmergencyTriggerAction
  address public immutable SAFE_ENTRYPOINT;

  /// @inheritdoc ISetEmergencyTriggerAction
  address public immutable EMERGENCY_TRIGGER;

  /**
   * @notice Constructor that sets up the SetEmergencyTriggerAction contract
   * @param _safeEntrypoint The safe entrypoint contract address that implements IEmergencyModeHook
   * @param _emergencyTrigger The emergency trigger address
   */
  constructor(address _safeEntrypoint, address _emergencyTrigger) {
    SAFE_ENTRYPOINT = _safeEntrypoint;
    EMERGENCY_TRIGGER = _emergencyTrigger;
  }

  // ~~~ ACTIONS METHODS ~~~

  /// @inheritdoc IActionsBuilder
  function getActions() external view returns (Action[] memory _actions) {
    _actions = new Action[](1);
    _actions[0] = Action({
      target: SAFE_ENTRYPOINT,
      data: abi.encodeCall(IEmergencyModeHook.setEmergencyTrigger, (EMERGENCY_TRIGGER)),
      value: 0
    });
  }
}
