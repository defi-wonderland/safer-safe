// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ActionsBuilder} from 'contracts/actions-builders/ActionsBuilder.sol';
import {IERC20} from 'forge-std/interfaces/IERC20.sol';
import {ISafeManageable} from 'interfaces/ISafeManageable.sol';
import {IAllowanceClaimor} from 'interfaces/actions-builders/IAllowanceClaimor.sol';

/**
 * @title AllowanceClaimor
 * @notice Contract that builds an action to send tokens from the token owner to the token recipient
 * @notice The amount to transfer is the max between the SAFE allowance of the token owner and the balance of the token owner
 */
contract AllowanceClaimor is IAllowanceClaimor, ActionsBuilder {
  // ~~~ STORAGE ~~~

  /// @inheritdoc IAllowanceClaimor
  IERC20 public immutable TOKEN;

  /// @inheritdoc IAllowanceClaimor
  address public immutable TOKEN_OWNER;

  /// @inheritdoc IAllowanceClaimor
  address public immutable TOKEN_RECIPIENT;

  // ~~~ CONSTRUCTOR ~~~

  /**
   * @notice Constructor that sets up the Safe, token, token owner and token recipient
   * @param _parent The parent that deployed the actions builder
   * @param _token The token contract address to be transferred
   * @param _tokenOwner The token owner address
   * @param _tokenRecipient The token recipient address
   */
  constructor(address _parent, address _token, address _tokenOwner, address _tokenRecipient) ActionsBuilder(_parent) {
    TOKEN = IERC20(_token);
    TOKEN_OWNER = _tokenOwner;
    TOKEN_RECIPIENT = _tokenRecipient;
  }

  // ~~~ ACTIONS METHODS ~~~

  /// @inheritdoc ActionsBuilder
  function getActions() external view override returns (Action[] memory _actions) {
    uint256 _amountToClaim = TOKEN.allowance(TOKEN_OWNER, address(ISafeManageable(msg.sender).SAFE()));
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
