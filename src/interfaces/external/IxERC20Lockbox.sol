// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title IxERC20Lockbox
 * @notice Interface for the xERC20Lockbox contract
 */
interface IxERC20Lockbox {
  // ~~~ ACTIONS METHODS ~~~

  /**
   * @notice Deposits an amount of tokens into the lockbox
   * @param _amount The amount of tokens to deposit
   */
  function deposit(uint256 _amount) external;
}
