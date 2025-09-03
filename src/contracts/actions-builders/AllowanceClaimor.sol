// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';
import {IAllowanceClaimor} from 'interfaces/actions-builders/IAllowanceClaimor.sol';

import {IERC20} from 'forge-std/interfaces/IERC20.sol';

/**
 * @title AllowanceClaimor
 * @notice Contract that builds actions from token allowances
 */
contract AllowanceClaimor is IAllowanceClaimor {
  // ~~~ STORAGE ~~~

  /// @inheritdoc IActionsBuilder
  address public immutable FACTORY;

  /// @inheritdoc IAllowanceClaimor
  address public immutable SAFE;

  /// @inheritdoc IAllowanceClaimor
  IERC20 public immutable TOKEN;

  /// @inheritdoc IAllowanceClaimor
  address public immutable TOKEN_OWNER;

  /// @inheritdoc IAllowanceClaimor
  address public immutable TOKEN_RECIPIENT;

  // ~~~ CONSTRUCTOR ~~~

  /**
   * @notice Constructor that sets up the Safe, token, token owner and token recipient
   * @param _factory The factory that deployed the action builder
   * @param _safe The Gnosis Safe contract address
   * @param _token The token contract address
   * @param _tokenOwner The token owner address
   * @param _tokenRecipient The token recipient address
   */
  constructor(address _factory, address _safe, address _token, address _tokenOwner, address _tokenRecipient) {
    FACTORY = _factory;
    SAFE = _safe;
    TOKEN = IERC20(_token);
    TOKEN_OWNER = _tokenOwner;
    TOKEN_RECIPIENT = _tokenRecipient;
  }

  // ~~~ ACTIONS METHODS ~~~

  /// @inheritdoc IActionsBuilder
  function getActions() external view returns (Action[] memory _actions) {
    uint256 _amountToClaim = TOKEN.allowance(TOKEN_OWNER, SAFE);
    uint256 _balance = TOKEN.balanceOf(TOKEN_OWNER);
    if (_amountToClaim > _balance) {
      _amountToClaim = _balance;
    }

    _actions = new Action[](1);
    _actions[0] = Action({
      target: address(TOKEN),
      data: abi.encodeCall(IERC20.transferFrom, (TOKEN_OWNER, TOKEN_RECIPIENT, _amountToClaim)),
      value: 0
    });
  }
}
