// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

/**
 * @title IUnsetEmergencyModeActionFactory
 * @notice Interface for the UnsetEmergencyModeActionFactory contract
 */
interface IUnsetEmergencyModeActionFactory {
  // ~~~ FACTORY METHODS ~~~

  /**
   * @notice Creates an UnsetEmergencyModeAction contract
   * @param _safeEntrypoint The safe entrypoint contract address
   * @return _unsetEmergencyModeAction The UnsetEmergencyModeAction contract address
   */
  function createUnsetEmergencyModeAction(address _safeEntrypoint) external returns (address _unsetEmergencyModeAction);
}
