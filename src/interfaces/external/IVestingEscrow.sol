// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title IVestingEscrow
 * @notice Interface for the VestingEscrow contract
 */
interface IVestingEscrow {
  /**
   * @notice Get the unclaimed amount
   * @return _amount The unclaimed amount of tokens
   */
  function unclaimed() external view returns (uint256 _amount);
}
