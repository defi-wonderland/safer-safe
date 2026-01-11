// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ActionsBuilder} from 'contracts/actions-builders/ActionsBuilder.sol';
import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';
import {IArbitraryActions} from 'interfaces/actions-builders/IArbitraryActions.sol';

/**
 * @title ArbitraryActions
 * @notice Contract that builds actions to perform simple transactions
 * @notice Each ArbitraryAction has a target, complete calldata and value
 * @notice An optional signature can be provided to verify the selector matches the callData
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
   * @notice If a signature is provided, it verifies that the selector matches the callData
   * @param _inputArbitraryActions The array of arbitrary actions
   */
  constructor(ArbitraryAction[] memory _inputArbitraryActions) ActionsBuilder(msg.sender) {
    uint256 _arbitraryActionsLength = _inputArbitraryActions.length;
    ArbitraryAction memory _arbitraryAction;
    Action memory _action;

    for (uint256 _i; _i < _arbitraryActionsLength; ++_i) {
      _arbitraryAction = _inputArbitraryActions[_i];

      // If signature provided, verify selector matches data
      if (bytes(_arbitraryAction.signature).length > 0) {
        bytes4 _expectedSelector = bytes4(keccak256(bytes(_arbitraryAction.signature)));
        bytes4 _actualSelector = bytes4(_arbitraryAction.data);
        if (_expectedSelector != _actualSelector) {
          revert SelectorMismatch(_expectedSelector, _actualSelector);
        }
      }

      _action = Action({target: _arbitraryAction.target, data: _arbitraryAction.data, value: _arbitraryAction.value});

      _actions.push(_action);
      emit ArbitraryActionAdded(
        _arbitraryAction.target, _arbitraryAction.data, _arbitraryAction.value, _arbitraryAction.signature
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
