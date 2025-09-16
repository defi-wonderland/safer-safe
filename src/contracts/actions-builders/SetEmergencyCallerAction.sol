// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ActionsBuilder} from 'contracts/actions-builders/ActionsBuilder.sol';
import {IEmergencyModeHook} from 'interfaces/IEmergencyModeHook.sol';
import {ISetEmergencyCallerAction} from 'interfaces/actions-builders/ISetEmergencyCallerAction.sol';

/**
 * @title SetEmergencyCallerAction
 * @notice Contract that builds an action to set the emergency caller
 * @notice The emergency caller is the address that can execute transactions in emergency mode
 * @dev Builds an action that calls IEmergencyModeHook.setEmergencyCaller
 */
contract SetEmergencyCallerAction is ISetEmergencyCallerAction, ActionsBuilder {
  /// @inheritdoc ISetEmergencyCallerAction
  address public immutable CANON_GUARD;

  /// @inheritdoc ISetEmergencyCallerAction
  address public immutable EMERGENCY_CALLER;

  /**
   * @notice Constructor that sets up the SetEmergencyCallerAction contract
   * @param _parent The parent that deployed the actions builder
   * @param _canonGuard The canon guard contract address that implements IEmergencyModeHook
   * @param _emergencyCaller The emergency caller address. This is the address that can execute transactions in emergency mode
   */
  constructor(address _parent, address _canonGuard, address _emergencyCaller) ActionsBuilder(_parent) {
    CANON_GUARD = _canonGuard;
    EMERGENCY_CALLER = _emergencyCaller;
  }

  // ~~~ ACTIONS METHODS ~~~

  /// @inheritdoc ActionsBuilder
  function getActions() external view override returns (Action[] memory _actions) {
    _actions = new Action[](1);
    _actions[0] = Action({
      target: CANON_GUARD,
      data: abi.encodeCall(IEmergencyModeHook.setEmergencyCaller, (EMERGENCY_CALLER)),
      value: 0
    });
  }
}
