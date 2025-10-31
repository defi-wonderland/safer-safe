// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ActionsBuilder} from 'contracts/actions-builders/ActionsBuilder.sol';
import {ICanonGuard} from 'interfaces/ICanonGuard.sol';
import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';
import {IPreApproveAction} from 'interfaces/actions-builders/IPreApproveAction.sol';

/**
 * @title PreApproveAction
 * @notice Contract that builds an action to approve the actions builder or action hub
 * @dev Builds an action that calls ICanonGuard.approveActionsBuilderOrHub with the approval duration
 */
contract PreApproveAction is IPreApproveAction, ActionsBuilder {
  /// @inheritdoc IPreApproveAction
  address public immutable ACTIONS_BUILDER;

  /// @inheritdoc IPreApproveAction
  uint256 public immutable APPROVAL_DURATION;

  /**
   * @notice Constructor that sets up the PreApproveAction contract
   * @param _actionsBuilder The actions builder or action hub contract address
   * @param _approvalDuration The approval duration
   */
  constructor(address _actionsBuilder, uint256 _approvalDuration) ActionsBuilder(msg.sender) {
    ACTIONS_BUILDER = _actionsBuilder;
    APPROVAL_DURATION = _approvalDuration;
  }

  // ~~~ ACTIONS METHODS ~~~

  /// @inheritdoc ActionsBuilder
  function getActions() external view override(ActionsBuilder, IActionsBuilder) returns (Action[] memory _actions) {
    _actions = new Action[](1);
    _actions[0] = Action({
      target: msg.sender,
      data: abi.encodeCall(ICanonGuard.approveActionsBuilderOrHub, (ACTIONS_BUILDER, APPROVAL_DURATION)),
      value: 0
    });
  }
}
