// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title IActionHub
 * @notice Interface for the ActionHub contract
 */
interface IActionHub {
  /**
   * @notice Emitted when a new actions builder is created
   * @param _actionsBuilder The address of the new actions builder
   * @param _initCode The init code of the new actions builder
   * @param _salt The salt used to deploy the new actions builder
   */
  event NewActionsBuilderCreated(address indexed _actionsBuilder, bytes _initCode, bytes32 _salt);

  /**
   * @notice Returns true if the actions builder is a child of the actionHub
   * @param _actionsBuilder The address of the actions builder to check
   * @return _isChild True if the actions builder is a child of the actionHub, false otherwise
   */
  function isChild(address _actionsBuilder) external view returns (bool _isChild);

  /**
   * @notice Gets the parent address
   * @return _parent The parent address
   */
  function PARENT() external view returns (address _parent);
}
