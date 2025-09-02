// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

/**
 * @title IDisapproveActionFactory
 * @notice Interface for the DisapproveActionFactory contract
 */
interface IDisapproveActionFactory {
  // ~~~ FACTORY METHODS ~~~

  /**
   * @notice Creates a DisapproveAction contract
   * @param _safeEntrypoint The SafeEntrypoint contract address
   * @param _actionsBuilder The actions builder contract address
   * @return _disapproveAction The DisapproveAction contract address
   */
  function createDisapproveAction(
    address _safeEntrypoint,
    address _actionsBuilder
  ) external returns (address _disapproveAction);
}
