// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IActionsBuilder} from 'interfaces/actions/IActionsBuilder.sol';

contract ActionsCaller {
  error ActionFailed(uint256 _index);

  function callActions(address _actionsBuilder) external payable {
    IActionsBuilder.Action[] memory _actions = IActionsBuilder(_actionsBuilder).getActions();

    for (uint256 _i; _i < _actions.length; ++_i) {
      IActionsBuilder.Action memory _action = _actions[_i];

      (bool _success,) = _action.target.call{value: _action.value}(_action.data);

      if (!_success) {
        revert ActionFailed(_i);
      }
    }
  }
}
