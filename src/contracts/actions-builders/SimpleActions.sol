// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';
import {ISimpleActions} from 'interfaces/actions-builders/ISimpleActions.sol';

/**
 * @title SimpleActions
 * @notice Contract that builds actions from simple actions
 */
contract SimpleActions is ISimpleActions {
  // ~~~ STORAGE ~~~

  /// @inheritdoc IActionsBuilder
  address public immutable FACTORY;

  /// @notice The array of actions
  Action[] internal _actions;

  // ~~~ CONSTRUCTOR ~~~

  /**
   * @notice Constructor that sets up the array of actions
   * @param _factory The factory that deployed the action builder
   * @param _simpleActions The array of simple actions
   */
  constructor(address _factory, SimpleAction[] memory _simpleActions) {
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

    FACTORY = _factory;
  }

  // ~~~ ACTIONS METHODS ~~~

  /// @inheritdoc IActionsBuilder
  function getActions() external view returns (Action[] memory) {
    return _actions;
  }
}
