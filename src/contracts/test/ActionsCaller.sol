// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ITransactionBuilder} from 'interfaces/actions/ITransactionBuilder.sol';

contract SimpleActionsCaller {
  error ActionFailed(uint256 _index);

  function callActions(address _txBuilder) external payable {
    ITransactionBuilder.Action[] memory _actions = ITransactionBuilder(_txBuilder).getActions();

    for (uint256 _i; _i < _actions.length; ++_i) {
      ITransactionBuilder.Action memory _action = _actions[_i];

      (bool _success,) = _action.target.call{value: _action.value}(_action.data);

      if (!_success) {
        revert ActionFailed(_i);
      }
    }
  }
}
