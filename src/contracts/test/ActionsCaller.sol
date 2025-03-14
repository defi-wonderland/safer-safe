// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.29;

import {IActions} from '../../interfaces/IActions.sol';

contract SimpleActionsCaller {
  error ActionFailed(uint256 index);

  function callActions(address _actions) external payable {
    IActions.Action[] memory actions = IActions(_actions).getActions();

    for (uint256 i = 0; i < actions.length; i++) {
      IActions.Action memory action = actions[i];

      (bool success,) = action.target.call{value: action.value}(action.data);

      if (!success) {
        revert ActionFailed(i);
      }
    }
  }
}
