// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ActionsBuilder} from 'contracts/actions-builders/ActionsBuilder.sol';
import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';
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

  /// @notice The array of simple actions
  SimpleAction[] internal _simpleActions;

  // ~~~ CONSTRUCTOR ~~~

  /**
   * @notice Constructor that sets up the array of actions containing the simple actions
   * @notice Each SimpleAction is converted into an Action to perform a simple transaction
   * @param _inputSimpleActions The array of simple actions
   */
  constructor(SimpleAction[] memory _inputSimpleActions) ActionsBuilder(msg.sender) {
    uint256 _simpleActionsLength = _inputSimpleActions.length;
    SimpleAction memory _simpleAction;
    Action memory _action;
    bytes4 _selector;
    bytes memory _completeCallData;

    for (uint256 _i; _i < _simpleActionsLength; ++_i) {
      _simpleAction = _inputSimpleActions[_i];

      _selector = bytes4(keccak256(bytes(_simpleAction.signature)));
      _completeCallData = abi.encodePacked(_selector, _simpleAction.data);

      _action = Action({target: _simpleAction.target, data: _completeCallData, value: _simpleAction.value});

      _actions.push(_action);
      emit SimpleActionAdded(_simpleAction.target, _simpleAction.signature, _simpleAction.data, _simpleAction.value);

      // Save the array for data availability
      _simpleActions.push(_inputSimpleActions[_i]);
    }
  }

  // ~~~ VIEW METHODS ~~~

  /// @inheritdoc ISimpleActions
  function simpleActions() external view returns (SimpleAction[] memory) {
    return _simpleActions;
  }

  // ~~~ ACTIONS METHODS ~~~

  /// @inheritdoc ActionsBuilder
  function getActions() external view override(ActionsBuilder, IActionsBuilder) returns (Action[] memory) {
    return _actions;
  }
}
