// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ICanonGuard} from 'interfaces/ICanonGuard.sol';
import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';
import {IApproveAction} from 'interfaces/actions-builders/IApproveAction.sol';

contract ApproveAction is IApproveAction {
  /// @inheritdoc IActionsBuilder
  address public immutable FACTORY;

  /// @inheritdoc IApproveAction
  address public immutable CANON_GUARD;

  /// @inheritdoc IApproveAction
  address public immutable ACTIONS_BUILDER;

  /// @inheritdoc IApproveAction
  uint256 public immutable APPROVAL_DURATION;

  /**
   * @notice Constructor that sets up the ApproveAction contract
   * @param _factory The factory that deployed the action builder
   * @param _canonGuard The CanonGuard contract address
   * @param _actionsBuilder The actions builder contract address
   * @param _approvalDuration The approval duration
   */
  constructor(address _factory, address _canonGuard, address _actionsBuilder, uint256 _approvalDuration) {
    FACTORY = _factory;
    CANON_GUARD = _canonGuard;
    ACTIONS_BUILDER = _actionsBuilder;
    APPROVAL_DURATION = _approvalDuration;
  }

  // ~~~ ACTIONS METHODS ~~~

  /// @inheritdoc IActionsBuilder
  function getActions() external view returns (Action[] memory _actions) {
    _actions = new Action[](1);
    _actions[0] = Action({
      target: CANON_GUARD,
      data: abi.encodeCall(ICanonGuard.approveActionsBuilderOrHub, (ACTIONS_BUILDER, APPROVAL_DURATION)),
      value: 0
    });
  }
}
