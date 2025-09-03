// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

/**
 * @title IActionsBuilder
 * @notice Interface for an ActionsBuilder contract
 */
interface IActionsBuilder {
  // ~~~ STRUCTS ~~~

  /**
   * @notice Struct for a transaction action
   * @param target The target address of the action (e.g., WETH)
   * @param data The data of the action (i.e., abi.encodeCall(function, (args)))
   * @param value The value of the action (i.e., msg.value)
   */
  struct Action {
    address target;
    bytes data;
    uint256 value;
  }

  // ~~~ ACTIONS METHODS ~~~

  /**
   * @notice Gets the list of transaction actions
   * @return _actions The array of actions
   */
  function getActions() external view returns (Action[] memory _actions);

  /**
   * @notice Gets the factory address
   * @return _factory The factory address. Returns address(0) if it was not deployed by a factory
   */
  function FACTORY() external view returns (address _factory);
}
