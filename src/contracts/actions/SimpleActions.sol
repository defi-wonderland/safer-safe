// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ISimpleActions} from 'interfaces/actions/ISimpleActions.sol';

contract SimpleActions is ISimpleActions {
  Action[] public actions;

  constructor(SimpleAction[] memory _actions) {
    uint256 _actionsLength = _actions.length;
    SimpleAction memory action;
    Action memory standardAction;
    bytes4 selector;
    bytes memory completeCallData;

    for (uint256 i; i < _actionsLength; ++i) {
      action = _actions[i];

      selector = bytes4(keccak256(bytes(action.signature)));
      completeCallData = abi.encodePacked(selector, action.data);

      standardAction = Action({target: action.target, data: completeCallData, value: action.value});

      actions.push(standardAction);
      emit SimpleActionAdded(action.target, action.signature, action.data, action.value);
    }
  }

  function getActions() external view returns (Action[] memory _actions) {
    _actions = actions;
  }
}
