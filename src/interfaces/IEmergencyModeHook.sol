// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ISafeManageable} from 'interfaces/ISafeManageable.sol';

interface IEmergencyModeHook is ISafeManageable {
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
