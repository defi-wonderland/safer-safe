// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

/**
 * @title ISetEmergencyTriggerAction
 * @notice Interface for the SetEmergencyTriggerAction contract
 */
interface ISetEmergencyTriggerAction {
  // ~~~ STORAGE METHODS ~~~

  /**
   * @notice Gets the canon guard contract address
   * @return _canonGuard The canon guard contract address
   */
  function CANON_GUARD() external view returns (address _canonGuard);

  /**
   * @notice Gets the emergency trigger address
   * @return _emergencyTrigger The emergency trigger address
   */
  function EMERGENCY_TRIGGER() external view returns (address _emergencyTrigger);
}
