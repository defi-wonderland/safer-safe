// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title IDisapproveActionFactory
 * @notice Interface for the DisapproveActionFactory contract
 */
interface IDisapproveActionFactory {
  // ~~~ FACTORY METHODS ~~~

  /**
   * @notice Creates a DisapproveAction contract
   * @param _actionsBuilder The actions builder contract address
   * @return _disapproveAction The DisapproveAction contract address
   */
  function createDisapproveAction(address _actionsBuilder) external returns (address _disapproveAction);
}
