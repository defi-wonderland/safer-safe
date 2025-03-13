// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import {IActions} from '../../interfaces/IActions.sol';
import {IERC20} from 'forge-std/interfaces/IERC20.sol';

contract TopupCoinbase is IActions {
  uint256 public tokenCooldown;
  address public immutable TOPUP_TOKEN;
  uint256 public immutable TOPUP_AMOUNT;

  address public constant COINBASE_DEPOSIT_ADDRESS = 0x0000000000000000000000000000000000000000;

  error TokenCooldown();

  function getActions() external returns (Action[] memory) {
    Action[] memory actions = new Action[](1);

    actions[0] = Action({
      target: TOPUP_TOKEN,
      data: abi.encodeWithSelector(IERC20.transfer.selector, COINBASE_DEPOSIT_ADDRESS, TOPUP_AMOUNT),
      value: 0
    });

    if (block.timestamp < tokenCooldown) {
      revert TokenCooldown();
    }

    tokenCooldown = block.timestamp + 1 days;

    return actions;
  }
}
