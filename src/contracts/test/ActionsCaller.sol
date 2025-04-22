// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.29;

import {IActions} from 'interfaces/actions/IActions.sol';

contract SimpleActionsCaller {
  error ActionFailed(uint256 _index);

  function callActions(address _actionContract) external payable {
    IActions.Action[] memory _actions = IActions(_actionContract).getActions();

    for (uint256 _i; _i < _actions.length; ++_i) {
      IActions.Action memory _action = _actions[_i];

      (bool _success,) = _action.target.call{value: _action.value}(_action.data);

      if (!_success) {
        revert ActionFailed(_i);
      }
    }
  }
}
