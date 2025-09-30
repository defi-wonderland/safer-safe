// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ActionsBuilder} from 'contracts/actions-builders/ActionsBuilder.sol';
import {ISimpleActions} from 'interfaces/actions-builders/ISimpleActions.sol';

/**
 * @title SimpleActions
 * @notice Contract that builds actions to perform simple transactions
 * @notice Each SimpleAction has a target, calldata and value
 */
contract SimpleActions is ISimpleActions, ActionsBuilder {
  // ~~~ STORAGE ~~~

  /// @notice The array of actions containing the simple actions to be executed
  Action[] internal _actions;

  // ~~~ CONSTRUCTOR ~~~

  /**
   * @notice Constructor that sets up the array of actions containing the simple actions
   * @notice Each SimpleAction is converted into an Action to perform a simple transaction
   * @param _parent The parent that deployed the actions builder
   * @param _simpleActions The array of simple actions
   */
  constructor(address _parent, SimpleAction[] memory _simpleActions) ActionsBuilder(_parent) {
    uint256 _simpleActionsLength = _simpleActions.length;
    SimpleAction memory _simpleAction;
    Action memory _action;
    bytes4 _selector;
    bytes memory _completeCallData;

    for (uint256 _i; _i < _simpleActionsLength; ++_i) {
      _simpleAction = _simpleActions[_i];

      _selector = bytes4(keccak256(bytes(_simpleAction.signature)));
      _completeCallData = abi.encodePacked(_selector, _simpleAction.data);

      _action = Action({target: _simpleAction.target, data: _completeCallData, value: _simpleAction.value});

      _actions.push(_action);
      emit SimpleActionAdded(_simpleAction.target, _simpleAction.signature, _simpleAction.data, _simpleAction.value);
    }
  }

  // ~~~ ACTIONS METHODS ~~~

  /// @inheritdoc ActionsBuilder
  function getActions() external view override returns (Action[] memory) {
    return _actions;
  }
}
