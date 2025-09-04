// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ActionsBuilder} from 'contracts/actions-builders/ActionsBuilder.sol';
import {ICanonGuard} from 'interfaces/ICanonGuard.sol';
import {IDisapproveAction} from 'interfaces/actions-builders/IDisapproveAction.sol';

contract DisapproveAction is IDisapproveAction, ActionsBuilder {
  /// @inheritdoc IDisapproveAction
  address public immutable CANON_GUARD;

  /// @inheritdoc IDisapproveAction
  address public immutable ACTIONS_BUILDER;

  /**
   * @notice Constructor that sets up the DisapproveAction contract
   * @param _parent The parent that deployed the actions buider
   * @param _canonGuard The CanonGuard contract address
   * @param _actionsBuilder The actions builder contract address
   */
  constructor(address _parent, address _canonGuard, address _actionsBuilder) ActionsBuilder(_parent) {
    CANON_GUARD = _canonGuard;
    ACTIONS_BUILDER = _actionsBuilder;
  }

  // ~~~ ACTIONS METHODS ~~~

  /// @inheritdoc ActionsBuilder
  function getActions() external view override returns (Action[] memory _actions) {
    _actions = new Action[](1);
    _actions[0] = Action({
      target: CANON_GUARD,
      data: abi.encodeCall(ICanonGuard.approveActionsBuilderOrHub, (ACTIONS_BUILDER, 0)),
      value: 0
    });
  }
}
