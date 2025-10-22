// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ActionsBuilder} from 'contracts/actions-builders/ActionsBuilder.sol';
import {IERC20} from 'forge-std/interfaces/IERC20.sol';
import {ISimpleTransfers} from 'interfaces/actions-builders/ISimpleTransfers.sol';

/**
 * @title SimpleTransfers
 * @notice Contract that builds actions to transfer ERC20 tokens
 */
contract SimpleTransfers is ISimpleTransfers, ActionsBuilder {
  // ~~~ STORAGE ~~~

  /// @notice The array of actions containing the transfer actions to be executed
  Action[] internal _actions;

  /// @notice The array of transfer actions
  TransferAction[] internal _transferActions;

  // ~~~ CONSTRUCTOR ~~~

  /**
   * @notice Constructor that sets up the array of actions containing the transfer actions
   * @notice Each TransferAction is converted into an Action to transfer an amount of ERC20 tokens to a recipient
   * @param _parent The parent that deployed the actions builder
   * @param _inputTransferActions The array of transfer actions
   */
  constructor(address _parent, TransferAction[] memory _inputTransferActions) ActionsBuilder(_parent) {
    uint256 _transferActionsLength = _inputTransferActions.length;
    TransferAction memory _transferAction;
    Action memory _action;

    for (uint256 _i; _i < _transferActionsLength; ++_i) {
      _transferAction = _inputTransferActions[_i];

      _action = Action({
        target: _transferAction.token,
        data: abi.encodeCall(IERC20.transfer, (_transferAction.to, _transferAction.amount)),
        value: 0
      });

      _actions.push(_action);
      emit TransferActionAdded(_transferAction.token, _transferAction.to, _transferAction.amount);

      // Save the array for data availability
      _transferActions.push(_inputTransferActions[_i]);
    }
  }

  // ~~~ VIEW METHODS ~~~

  /// @inheritdoc ISimpleTransfers
  function transferActions() external view returns (TransferAction[] memory) {
    return _transferActions;
  }

  // ~~~ ACTIONS METHODS ~~~

  /// @inheritdoc ActionsBuilder
  function getActions() external view override returns (Action[] memory) {
    return _actions;
  }
}
