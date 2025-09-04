// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IEmergencyModeHook} from 'interfaces/IEmergencyModeHook.sol';
import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';
import {ISetEmergencyCallerAction} from 'interfaces/actions-builders/ISetEmergencyCallerAction.sol';

contract SetEmergencyCallerAction is ISetEmergencyCallerAction {
  /// @inheritdoc ISetEmergencyCallerAction
  address public immutable CANON_GUARD;

  /// @inheritdoc ISetEmergencyCallerAction
  address public immutable EMERGENCY_CALLER;

  /**
   * @notice Constructor that sets up the SetEmergencyCallerAction contract
   * @param _canonGuard The canon guard contract address that implements IEmergencyModeHook
   * @param _emergencyCaller The emergency caller address
   */
  constructor(address _canonGuard, address _emergencyCaller) {
    CANON_GUARD = _canonGuard;
    EMERGENCY_CALLER = _emergencyCaller;
  }

  // ~~~ ACTIONS METHODS ~~~

  /// @inheritdoc IActionsBuilder
  function getActions() external view returns (Action[] memory _actions) {
    _actions = new Action[](1);
    _actions[0] = Action({
      target: CANON_GUARD,
      data: abi.encodeCall(IEmergencyModeHook.setEmergencyCaller, (EMERGENCY_CALLER)),
      value: 0
    });
  }
}
