// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ActionsBuilder} from 'contracts/actions-builders/ActionsBuilder.sol';
import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';
import {IArbitraryActions} from 'interfaces/actions-builders/IArbitraryActions.sol';

/**
 * @title ArbitraryActions
 * @notice Contract that builds actions to perform simple transactions
 * @notice Each ArbitraryAction has a target, calldata and value
 */
contract ArbitraryActions is IArbitraryActions, ActionsBuilder {
  // ~~~ STORAGE ~~~

  /// @notice The array of actions containing the arbitrary actions to be executed
  Action[] internal _actions;

  /// @notice The array of arbitrary actions
  ArbitraryAction[] internal _arbitraryActions;

  // ~~~ CONSTRUCTOR ~~~

  /**
   * @notice Constructor that sets up the array of actions containing the arbitrary actions
   * @notice Each ArbitraryAction is converted into an Action to perform a simple transaction
   * @param _inputArbitraryActions The array of arbitrary actions
   */
  constructor(ArbitraryAction[] memory _inputArbitraryActions) ActionsBuilder(msg.sender) {
    uint256 _arbitraryActionsLength = _inputArbitraryActions.length;
    ArbitraryAction memory _arbitraryAction;
    Action memory _action;
    bytes4 _selector;
    bytes memory _completeCallData;

    for (uint256 _i; _i < _arbitraryActionsLength; ++_i) {
      _arbitraryAction = _inputArbitraryActions[_i];

      _selector = bytes4(keccak256(bytes(_arbitraryAction.signature)));
      _completeCallData = abi.encodePacked(_selector, _arbitraryAction.data);

      _action = Action({target: _arbitraryAction.target, data: _completeCallData, value: _arbitraryAction.value});

      _actions.push(_action);
      emit ArbitraryActionAdded(
        _arbitraryAction.target, _arbitraryAction.signature, _arbitraryAction.data, _arbitraryAction.value
      );

      // Save the array for data availability
      _arbitraryActions.push(_inputArbitraryActions[_i]);
    }
  }

  // ~~~ VIEW METHODS ~~~

  /// @inheritdoc IArbitraryActions
  function arbitraryActions() external view returns (ArbitraryAction[] memory) {
    return _arbitraryActions;
  }

  // ~~~ ACTIONS METHODS ~~~

  /// @inheritdoc ActionsBuilder
  function getActions() external view override(ActionsBuilder, IActionsBuilder) returns (Action[] memory) {
    return _actions;
  }
}
