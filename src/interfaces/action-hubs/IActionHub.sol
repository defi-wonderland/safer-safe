// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

/**
 * @title IActionHub
 * @notice Interface for the ActionHub contract
 */
interface IActionHub {
  /**
   * @notice Emitted when a new actions buider is created
   * @param _actionsBuilder The address of the new actions buider
   * @param _initCode The init code of the new actions buider
   * @param _salt The salt used to deploy the new actions buider
   */
  event NewActionsBuilderCreated(address indexed _actionsBuilder, bytes _initCode, bytes32 _salt);

  /**
   * @notice Returns true if the actions buider is a child of the actionHub
   * @param _actionsBuilder The address of the actions buider to check
   * @return _isChild True if the actions buider is a child of the actionHub, false otherwise
   */
  function isChild(address _actionsBuilder) external view returns (bool _isChild);

  /**
   * @notice Gets the parent address
   * @return _parent The parent address
   */
  function PARENT() external view returns (address _parent);
}
