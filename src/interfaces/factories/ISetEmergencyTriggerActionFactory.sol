// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title ISetEmergencyTriggerActionFactory
 * @notice Interface for the SetEmergencyTriggerActionFactory contract
 */
interface ISetEmergencyTriggerActionFactory {
  // ~~~ EVENTS ~~~

  /**
   * @notice Emitted when a new SetEmergencyTriggerAction contract is created
   * @param _setEmergencyTriggerAction The address of the created SetEmergencyTriggerAction contract
   * @param _emergencyTrigger The emergency trigger address
   */
  event SetEmergencyTriggerActionCreated(address indexed _setEmergencyTriggerAction, address indexed _emergencyTrigger);

  // ~~~ FACTORY METHODS ~~~

  /**
   * @notice Creates a SetEmergencyTriggerAction contract
   * @param _emergencyTrigger The emergency trigger address
   * @return _setEmergencyTriggerAction The SetEmergencyTriggerAction contract address
   */
  function createSetEmergencyTriggerAction(address _emergencyTrigger)
    external
    returns (address _setEmergencyTriggerAction);
}
