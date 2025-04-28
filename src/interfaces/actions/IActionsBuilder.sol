// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

/**
 * @title IActionsBuilder
 * @notice Interface for a ActionsBuilder contract
 */
interface IActionsBuilder {
  // ~~~ STRUCTS ~~~

  /**
   * @notice Struct for a transaction action
   * @param target The target address of the action
   * @param data The data of the action
   * @param value The value of the action
   */
  struct Action {
    address target;
    bytes data;
    uint256 value;
  }

  // ~~~ VIEW METHODS ~~~

  /**
   * @notice Gets the list of transaction actions
   * @return _actions The array of actions
   */
  function getActions() external returns (Action[] memory _actions);
}
