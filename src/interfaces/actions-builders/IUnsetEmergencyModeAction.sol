// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';

/**
 * @title IUnsetEmergencyModeAction
 * @notice Interface for the UnsetEmergencyModeAction contract
 */
interface IUnsetEmergencyModeAction is IActionsBuilder {
  // ~~~ STORAGE METHODS ~~~

  /**
   * @notice Gets the canon guard contract address
   * @return _canonGuard The canon guard contract address
   */
  function CANON_GUARD() external view returns (address _canonGuard);
}
