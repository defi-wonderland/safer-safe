// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title ISetEmergencyCallerAction
 * @notice Interface for the SetEmergencyCallerAction contract
 */
interface ISetEmergencyCallerAction {
  // ~~~ STORAGE METHODS ~~~

  /**
   * @notice Gets the canon guard contract address
   * @return _canonGuard The canon guard contract address
   */
  function CANON_GUARD() external view returns (address _canonGuard);

  /**
   * @notice Gets the emergency caller address
   * @return _emergencyCaller The emergency caller address
   */
  function EMERGENCY_CALLER() external view returns (address _emergencyCaller);
}
