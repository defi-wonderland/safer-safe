// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';

/**
 * @title IDisapproveAction
 * @notice Interface for the DisapproveAction contract
 */
interface IDisapproveAction is IActionsBuilder {
  // ~~~ STORAGE METHODS ~~~

  /**
   * @notice Gets the safe canon guard contract
   * @return _canonGuard The safe canon guard contract address
   */
  function CANON_GUARD() external view returns (address _canonGuard);

  /**
   * @notice Gets the actions builder contract
   * @return _actionsBuilder The actions builder contract address
   */
  function ACTIONS_BUILDER() external view returns (address _actionsBuilder);
}
