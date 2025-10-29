// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title ISetEmergencyCallerActionFactory
 * @notice Interface for the SetEmergencyCallerActionFactory contract
 */
interface ISetEmergencyCallerActionFactory {
  // ~~~ EVENTS ~~~

  /**
   * @notice Emitted when a new SetEmergencyCallerAction contract is created
   * @param _setEmergencyCallerAction The address of the created SetEmergencyCallerAction contract
   * @param _emergencyCaller The emergency caller address
   */
  event SetEmergencyCallerActionCreated(address indexed _setEmergencyCallerAction, address indexed _emergencyCaller);

  // ~~~ FACTORY METHODS ~~~

  /**
   * @notice Creates a SetEmergencyCallerAction contract
   * @param _emergencyCaller The emergency caller address
   * @return _setEmergencyCallerAction The SetEmergencyCallerAction contract address
   */
  function createSetEmergencyCallerAction(address _emergencyCaller) external returns (address _setEmergencyCallerAction);
}
