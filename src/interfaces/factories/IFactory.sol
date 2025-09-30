// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title IFactory
 * @notice Interface for the Factory contract
 */
interface IFactory {
  // ~~~ FUNCTIONS ~~~

  /**
   * @notice Returns true if the contract was created by the factory
   * @param _contract The contract address
   * @return _isChild True if the contract was created by the factory, false otherwise
   */
  function isChild(address _contract) external view returns (bool _isChild);
}
