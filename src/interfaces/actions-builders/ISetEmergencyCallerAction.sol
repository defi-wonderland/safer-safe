// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';

/**
 * @title ISetEmergencyCallerAction
 * @notice Interface for the SetEmergencyCallerAction contract
 */
interface ISetEmergencyCallerAction is IActionsBuilder {
  // ~~~ STORAGE METHODS ~~~

  /**
   * @notice Gets the emergency caller address
   * @return _emergencyCaller The emergency caller address
   */
  function EMERGENCY_CALLER() external view returns (address _emergencyCaller);
}
