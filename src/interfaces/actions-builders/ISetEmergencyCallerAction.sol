// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';

/**
 * @title ISetEmergencyCallerAction
 * @notice Interface for the SetEmergencyCallerAction contract
 */
interface ISetEmergencyCallerAction is IActionsBuilder {
  // ~~~ STORAGE METHODS ~~~

  /**
   * @notice Gets the safe entrypoint contract address
   * @return _safeEntrypoint The safe entrypoint contract address
   */
  function SAFE_ENTRYPOINT() external view returns (address _safeEntrypoint);

  /**
   * @notice Gets the emergency caller address
   * @return _emergencyCaller The emergency caller address
   */
  function EMERGENCY_CALLER() external view returns (address _emergencyCaller);
}
