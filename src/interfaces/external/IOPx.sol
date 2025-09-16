// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title IOPx
 * @notice Interface for the OPx contract
 */
interface IOPx {
  /**
   * @notice Downgrades the OPx balance of the sender
   * @param _amount The amount of OPx to downgrade
   */
  function downgrade(uint256 _amount) external;
}
