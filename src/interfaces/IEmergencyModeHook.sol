// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IEmergencyModeHook {
  // ~~~ EVENTS ~~~

  /**
   * @notice Emitted when emergency mode is activated
   */
  event EmergencyModeSet();

  /**
   * @notice Emitted when emergency mode is deactivated
   */
  event EmergencyModeUnset();

  /**
   * @notice Emitted when the emergency caller is updated
   * @param _oldCaller The previous emergency caller address
   * @param _newCaller The new emergency caller address
   */
  event EmergencyCallerSet(address indexed _oldCaller, address indexed _newCaller);

  /**
   * @notice Emitted when the emergency trigger is updated
   * @param _oldTrigger The previous emergency trigger address
   * @param _newTrigger The new emergency trigger address
   */
  event EmergencyTriggerSet(address indexed _oldTrigger, address indexed _newTrigger);

  // ~~~ ERRORS ~~~

  /**
   * @notice Thrown when a transaction is attempted by an unauthorized sender
   * @param _sender The unauthorized sender address
   * @param _authorized The authorized address
   */
  error Unauthorized(address _sender, address _authorized);

  /**
   * @notice Thrown when the zero address is provided
   */
  error ZeroAddress();

  // ~~~ ADMIN METHODS ~~~

  /**
   * @notice Sets the emergency mode
   */
  function setEmergencyMode() external;

  /**
   * @notice Unsets the emergency mode
   */
  function unsetEmergencyMode() external;

  /**
   * @notice Sets the emergency caller address
   * @param _emergencyCaller The emergency caller address
   */
  function setEmergencyCaller(address _emergencyCaller) external;

  /**
   * @notice Sets the emergency trigger address
   * @param _emergencyTrigger The emergency trigger address
   */
  function setEmergencyTrigger(address _emergencyTrigger) external;

  // ~~~ STORAGE METHODS ~~~

  /**
   * @notice Returns the emergency mode status
   * @return _emergencyMode The emergency mode status
   */
  function emergencyMode() external view returns (bool _emergencyMode);

  /**
   * @notice Returns the emergency caller address
   * @return _emergencyCaller The emergency caller address
   */
  function emergencyCaller() external view returns (address _emergencyCaller);

  /**
   * @notice Returns the emergency trigger address
   * @return _emergencyTrigger The emergency trigger address
   */
  function emergencyTrigger() external view returns (address _emergencyTrigger);
}
