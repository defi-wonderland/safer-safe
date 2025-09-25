// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ActionHubChild} from 'contracts/action-hubs/ActionHubChild.sol';
import {ActionsBuilder} from 'contracts/actions-builders/ActionsBuilder.sol';
import {IERC20} from 'forge-std/interfaces/IERC20.sol';
import {ICappedTokenTransfersHub} from 'interfaces/action-hubs/ICappedTokenTransfersHub.sol';
import {ICappedTokenTransfers} from 'interfaces/actions-builders/ICappedTokenTransfers.sol';

/**
 * @title CappedTokenTransfers
 * @notice Contract that builds actions from capped token transfers
 */
contract CappedTokenTransfers is ICappedTokenTransfers, ActionHubChild, ActionsBuilder {
  // ~~~ STORAGE ~~~

  /// @inheritdoc ICappedTokenTransfers
  address public immutable TOKEN;

  /// @inheritdoc ICappedTokenTransfers
  uint256 public immutable AMOUNT;

  /// @inheritdoc ICappedTokenTransfers
  address public immutable RECIPIENT;

  // ~~~ CONSTRUCTOR ~~~

  /**
   * @notice Constructor that sets up the token, amount and recipient
   * @param _parent The parent that deployed the actions builder
   * @param _token The token contract address
   * @param _amount The amount of tokens to transfer
   * @param _recipient The recipient of the tokens
   * @param _actionHub The parent hub of the action. In this case, it's the hub of the CappedTokenTransfersHub contract
   */
  constructor(
    address _parent,
    address _token,
    uint256 _amount,
    address _recipient,
    address _actionHub
  ) ActionsBuilder(_parent) ActionHubChild(_actionHub) {
    TOKEN = _token;
    AMOUNT = _amount;
    RECIPIENT = _recipient;
  }

  // ~~~ ACTIONS METHODS ~~~

  /// @inheritdoc ActionsBuilder
  function getActions() external view override returns (Action[] memory _actions) {
    _actions = new Action[](2);

    // First action: update state
    _actions[0] =
      Action({target: HUB, data: abi.encodeCall(ICappedTokenTransfersHub.updateState, (TOKEN, AMOUNT)), value: 0});

    // Second action: transfer
    _actions[1] = Action({target: TOKEN, data: abi.encodeCall(IERC20.transfer, (RECIPIENT, AMOUNT)), value: 0});
  }
}
