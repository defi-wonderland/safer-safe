// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.29;

import {IAllowanceClaimor} from 'interfaces/actions/IAllowanceClaimor.sol';

import {IERC20} from 'forge-std/interfaces/IERC20.sol';

contract AllowanceClaimor is IAllowanceClaimor {
  address public immutable SAFE;
  address public immutable TOKEN;
  address public immutable TOKEN_OWNER;
  address public immutable TOKEN_RECIPIENT;

  constructor(address _safe, address _token, address _tokenOwner, address _tokenRecipient) {
    SAFE = _safe;
    TOKEN = _token;
    TOKEN_OWNER = _tokenOwner;
    TOKEN_RECIPIENT = _tokenRecipient;
  }

  function getActions() external view returns (Action[] memory) {
    uint256 amountToClaim = IERC20(TOKEN).allowance(TOKEN_OWNER, SAFE);
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
