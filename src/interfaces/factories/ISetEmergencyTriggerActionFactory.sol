// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

/**
 * @title ISetEmergencyTriggerActionFactory
 * @notice Interface for the SetEmergencyTriggerActionFactory contract
 */
interface ISetEmergencyTriggerActionFactory {
  // ~~~ FACTORY METHODS ~~~

  /**
   * @notice Creates a SetEmergencyTriggerAction contract
   * @param _canonGuard The canon guard contract address
   * @param _emergencyTrigger The emergency trigger address
   * @return _setEmergencyTriggerAction The SetEmergencyTriggerAction contract address
   */
  function createSetEmergencyTriggerAction(
    address _canonGuard,
    address _emergencyTrigger
  ) external returns (address _setEmergencyTriggerAction);
}
