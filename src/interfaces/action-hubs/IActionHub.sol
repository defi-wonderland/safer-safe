// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

/**
 * @title IActionHub
 * @notice Interface for the ActionHub contract
 */
interface IActionHub {
  /**
   * @notice Emitted when a new action builder is created
   * @param _actionBuilder The address of the new action builder
   * @param _initCode The init code of the new action builder
   * @param _salt The salt used to deploy the new action builder
   */
  event NewActionBuilderCreated(address indexed _actionBuilder, bytes _initCode, bytes32 _salt);

  /**
   * @notice Returns true if the action builder is a child of the actionHub
   * @param _actionBuilder The address of the action builder to check
   * @return _isChild True if the action builder is a child of the actionHub, false otherwise
   */
  function isChild(address _actionBuilder) external view returns (bool _isChild);

  /**
   * @notice Gets the parent address
   * @return _parent The parent address
   */
  function PARENT() external view returns (address _parent);
}
