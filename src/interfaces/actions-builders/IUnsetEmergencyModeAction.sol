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
   * @notice Gets the safe entrypoint contract address
   * @return _safeEntrypoint The safe entrypoint contract address
   */
  function SAFE_ENTRYPOINT() external view returns (address _safeEntrypoint);
}
