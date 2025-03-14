// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import {IActions} from '../../interfaces/IActions.sol';
import {SimpleAction} from '../../interfaces/SimpleAction.sol';

contract SimpleActions is IActions {
  Action[] public actions;

  event SimpleActionAdded(address indexed target, string signature, bytes data, uint256 value);

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

  function getActions() external view returns (Action[] memory) {
    return actions;
  }
}
