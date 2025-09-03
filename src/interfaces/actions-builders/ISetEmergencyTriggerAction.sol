// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';

/**
 * @title ISetEmergencyTriggerAction
 * @notice Interface for the SetEmergencyTriggerAction contract
 */
interface ISetEmergencyTriggerAction is IActionsBuilder {
  // ~~~ STORAGE METHODS ~~~

  /**
   * @notice Gets the safe entrypoint contract address
   * @return _safeEntrypoint The safe entrypoint contract address
   */
  function SAFE_ENTRYPOINT() external view returns (address _safeEntrypoint);

  /**
   * @notice Gets the emergency trigger address
   * @return _emergencyTrigger The emergency trigger address
   */
  function EMERGENCY_TRIGGER() external view returns (address _emergencyTrigger);
}
