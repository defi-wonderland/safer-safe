// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IERC20} from 'forge-std/interfaces/IERC20.sol';

import {ICappedTokenTransfersHub} from 'interfaces/action-hubs/ICappedTokenTransfersHub.sol';
import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';
import {ICappedTokenTransfers} from 'interfaces/actions-builders/ICappedTokenTransfers.sol';

/**
 * @title CappedTokenTransfers
 * @notice Contract that builds actions from capped token transfers
 */
contract CappedTokenTransfers is ICappedTokenTransfers {
  // ~~~ STORAGE ~~~

  /// @inheritdoc ICappedTokenTransfers
  address public immutable TOKEN;

  /// @inheritdoc ICappedTokenTransfers
  uint256 public immutable AMOUNT;

  /// @inheritdoc ICappedTokenTransfers
  address public immutable RECIPIENT;

  /// @inheritdoc ICappedTokenTransfers
  address public immutable HUB;

  // ~~~ CONSTRUCTOR ~~~

  /**
   * @notice Constructor that sets up the token, amount and recipient
   * @param _token The token contract address
   * @param _amount The amount of tokens to transfer
   * @param _recipient The recipient of the tokens
   * @param _actionHub The hub of the action
   */
  constructor(address _token, uint256 _amount, address _recipient, address _actionHub) {
    TOKEN = _token;
    AMOUNT = _amount;
    RECIPIENT = _recipient;
    HUB = _actionHub;
  }

  // ~~~ ACTIONS METHODS ~~~

  /// @inheritdoc IActionsBuilder
  function getActions() external view returns (Action[] memory _actions) {
    _actions = new Action[](2);

    // First action: update state
    _actions[0] =
      Action({target: HUB, data: abi.encodeCall(ICappedTokenTransfersHub.updateState, (TOKEN, AMOUNT)), value: 0});

    // Second action: transfer
    _actions[1] = Action({target: TOKEN, data: abi.encodeCall(IERC20.transfer, (RECIPIENT, AMOUNT)), value: 0});

    return _actions;
  }
}
