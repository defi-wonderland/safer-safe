// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import {IActions} from '../../interfaces/IActions.sol';
import {IERC20} from 'forge-std/interfaces/IERC20.sol';

contract AllowanceClaimor is IActions {
  address public immutable TOKEN;
  address public immutable TOKEN_OWNER;
  address public immutable TOKEN_RECIPIENT;

  constructor(address _token, address _tokenOwner, address _tokenRecipient) {
    TOKEN = _token;
    TOKEN_OWNER = _tokenOwner;
    TOKEN_RECIPIENT = _tokenRecipient;
  }

  function getActions() external view returns (Action[] memory) {
    uint256 amountToClaim = IERC20(TOKEN).allowance(TOKEN_OWNER, TOKEN_RECIPIENT);
    uint256 balance = IERC20(TOKEN).balanceOf(TOKEN_OWNER);
    if (amountToClaim > balance) {
      amountToClaim = balance;
    }

    Action[] memory actions = new Action[](1);
    actions[0] = Action({
      target: TOKEN,
      data: abi.encodeWithSelector(IERC20.transferFrom.selector, TOKEN_OWNER, TOKEN_RECIPIENT, amountToClaim),
      value: 0
    });

    return actions;
  }
}
