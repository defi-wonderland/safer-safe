// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import {IActions} from '../../interfaces/IActions.sol';
import {IERC20} from 'forge-std/interfaces/IERC20.sol';

contract OpClaimor is IActions {
  address public constant OP_TOKEN = 0x0000000000000000000000000000000000000000;
  address public constant OP_RPG_TREASURY = 0x0000000000000000000000000000000000000000;
  address public constant WONDER_MULTISIG = 0x0000000000000000000000000000000000000000;

  function getActions() external returns (Action[] memory) {
    uint256 amountToClaim = IERC20(OP_TOKEN).allowance(OP_RPG_TREASURY, WONDER_MULTISIG);

    Action[] memory actions = new Action[](1);
    actions[0] = Action({
      target: OP_TOKEN,
      data: abi.encodeWithSelector(IERC20.transferFrom.selector, OP_RPG_TREASURY, WONDER_MULTISIG, amountToClaim),
      value: 0
    });

    return actions;
  }
}
