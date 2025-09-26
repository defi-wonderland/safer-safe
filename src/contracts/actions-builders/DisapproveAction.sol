// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ActionsBuilder} from 'contracts/actions-builders/ActionsBuilder.sol';
import {ICanonGuard} from 'interfaces/ICanonGuard.sol';
import {IDisapproveAction} from 'interfaces/actions-builders/IDisapproveAction.sol';

/**
 * @title DisapproveAction
 * @notice Contract that builds an action to disapprove the actions builder or action hub
 * @dev Builds an action that calls ICanonGuard.approveActionsBuilderOrHub with a 0 approval duration
 */
contract DisapproveAction is IDisapproveAction, ActionsBuilder {
  /// @inheritdoc IDisapproveAction
  address public immutable ACTIONS_BUILDER;

  /**
   * @notice Constructor that sets up the DisapproveAction contract
   * @param _parent The parent that deployed the actions builder
   * @param _actionsBuilder The actions builder or action hub contract address
   */
  constructor(address _parent, address _actionsBuilder) ActionsBuilder(_parent) {
    ACTIONS_BUILDER = _actionsBuilder;
  }

  // ~~~ ACTIONS METHODS ~~~

  /// @inheritdoc ActionsBuilder
  function getActions() external view override returns (Action[] memory _actions) {
    _actions = new Action[](1);
    _actions[0] = Action({
      target: msg.sender,
      data: abi.encodeCall(ICanonGuard.approveActionsBuilderOrHub, (ACTIONS_BUILDER, 0)),
      value: 0
    });
  }
}
