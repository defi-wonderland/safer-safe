// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title ISimpleTransfers
 * @notice Interface for the SimpleTransfers contract
 */
interface ISimpleTransfers {
  // ~~~ STRUCTS ~~~

  /**
   * @notice Struct for a token transfer action
   * @param token The token address of the transfer (e.g., WETH)
   * @param to The recipient address of the transfer (e.g., msg.sender)
   * @param amount The amount of the transfer (e.g., 1 ether)
   */
  struct TransferAction {
    address token;
    address to;
    uint256 amount;
  }

  // ~~~ EVENTS ~~~

  /**
   * @notice Emitted when a transfer action is added
   * @param _token The token address of the transfer
   * @param _to The recipient address of the transfer
   * @param _amount The amount of the transfer
   */
  event TransferActionAdded(address indexed _token, address indexed _to, uint256 _amount);
}
