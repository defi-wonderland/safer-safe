// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IEmergencyModeHook} from 'interfaces/IEmergencyModeHook.sol';
import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';
import {ISetEmergencyCallerAction} from 'interfaces/actions-builders/ISetEmergencyCallerAction.sol';

contract SetEmergencyCallerAction is ISetEmergencyCallerAction {
  /// @inheritdoc ISetEmergencyCallerAction
  address public immutable SAFE_ENTRYPOINT;

  /// @inheritdoc ISetEmergencyCallerAction
  address public immutable EMERGENCY_CALLER;

  /**
   * @notice Constructor that sets up the SetEmergencyCallerAction contract
   * @param _safeEntrypoint The safe entrypoint contract address that implements IEmergencyModeHook
   * @param _emergencyCaller The emergency caller address
   */
  constructor(address _safeEntrypoint, address _emergencyCaller) {
    SAFE_ENTRYPOINT = _safeEntrypoint;
    EMERGENCY_CALLER = _emergencyCaller;
  }

  // ~~~ ACTIONS METHODS ~~~

  /// @inheritdoc IActionsBuilder
  function getActions() external view returns (Action[] memory _actions) {
    _actions = new Action[](1);
    _actions[0] = Action({
      target: SAFE_ENTRYPOINT,
      data: abi.encodeCall(IEmergencyModeHook.setEmergencyCaller, (EMERGENCY_CALLER)),
      value: 0
    });
  }
}
