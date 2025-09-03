// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

/**
 * @title ISetEmergencyCallerActionFactory
 * @notice Interface for the SetEmergencyCallerActionFactory contract
 */
interface ISetEmergencyCallerActionFactory {
  // ~~~ FACTORY METHODS ~~~

  /**
   * @notice Creates a SetEmergencyCallerAction contract
   * @param _safeEntrypoint The safe entrypoint contract address
   * @param _emergencyCaller The emergency caller address
   * @return _setEmergencyCallerAction The SetEmergencyCallerAction contract address
   */
  function createSetEmergencyCallerAction(
    address _safeEntrypoint,
    address _emergencyCaller
  ) external returns (address _setEmergencyCallerAction);
}
