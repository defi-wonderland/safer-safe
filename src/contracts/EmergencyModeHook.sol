// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {SafeManageable} from 'contracts/SafeManageable.sol';
import {IEmergencyModeHook} from 'interfaces/IEmergencyModeHook.sol';

/**
 * @title EmergencyModeHook
 * @notice Hook that allows for the execution of transactions in emergency mode
 */
abstract contract EmergencyModeHook is IEmergencyModeHook, SafeManageable {
  // ~~~ STORAGE ~~~

  /// @inheritdoc IEmergencyModeHook
  bool public emergencyMode;
  /// @inheritdoc IEmergencyModeHook
  address public emergencyCaller;
  /// @inheritdoc IEmergencyModeHook
  address public emergencyTrigger;

  // ~~~ CONSTRUCTOR ~~~

  /**
   * @notice Constructor that sets up the emergency mode hook
   * @param _emergencyTrigger The emergency trigger address
   * @param _emergencyCaller The emergency caller address
   * @param _safe The safe address
   */
  constructor(address _emergencyTrigger, address _emergencyCaller, address _safe) SafeManageable(_safe) {
    if (_emergencyTrigger == address(0)) revert ZeroAddress();
    if (_emergencyCaller == address(0)) revert ZeroAddress();

    emergencyTrigger = _emergencyTrigger;
    emergencyCaller = _emergencyCaller;
  }

  // ~~~ ADMIN METHODS ~~~

  /// @inheritdoc IEmergencyModeHook
  function setEmergencyMode() external {
    if (msg.sender != emergencyTrigger) revert Unauthorized(msg.sender, emergencyTrigger);
    emergencyMode = true;
  }

  /// @inheritdoc IEmergencyModeHook
  function unsetEmergencyMode() external isSafe {
    emergencyMode = false;
  }

  /// @inheritdoc IEmergencyModeHook
  function setEmergencyCaller(address _emergencyCaller) external isSafe {
    if (_emergencyCaller == address(0)) revert ZeroAddress();
    emergencyCaller = _emergencyCaller;
  }

  /// @inheritdoc IEmergencyModeHook
  function setEmergencyTrigger(address _emergencyTrigger) external isSafe {
    if (_emergencyTrigger == address(0)) revert ZeroAddress();
    emergencyTrigger = _emergencyTrigger;
  }

  // ~~~ INTERNAL METHODS ~~~

  /**
   * @notice Hook that is called before the execution of a transaction.
   * @dev used to check if the transaction is authorized to be executed in emergency mode.
   */
  function _onBeforeExecution() internal virtual {
    if (emergencyMode && msg.sender != emergencyCaller) {
      revert Unauthorized(msg.sender, emergencyCaller);
    }
  }
}
