// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ISimpleActions} from 'interfaces/actions/ISimpleActions.sol';

contract SimpleActions is ISimpleActions {
  Action[] public actions;

  constructor(SimpleAction[] memory _actions) {
    for (uint256 i = 0; i < _actions.length; i++) {
      SimpleAction memory action = _actions[i];

      bytes4 selector = bytes4(keccak256(bytes(action.signature)));
      bytes memory completeCallData = abi.encodePacked(selector, action.data);

      Action memory standardAction = Action({target: action.target, data: completeCallData, value: action.value});

      actions.push(standardAction);
      emit SimpleActionAdded(action.target, action.signature, action.data, action.value);
    }
  }

  function getActions() external view returns (Action[] memory _actions) {
    _actions = actions;
  }
}
