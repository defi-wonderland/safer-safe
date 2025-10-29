// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';

/**
 * @title ISimpleTransfers
 * @notice Interface for the SimpleTransfers contract
 */
interface ISimpleTransfers is IActionsBuilder {
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

  // ~~~ VIEW METHODS ~~~

  /**
   * @notice Gets the array of transfer actions
   * @return _transferActions The array of transfer actions
   */
  function transferActions() external view returns (TransferAction[] memory _transferActions);
}
