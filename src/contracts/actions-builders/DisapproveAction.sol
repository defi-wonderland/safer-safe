// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ISafeEntrypoint} from 'interfaces/ISafeEntrypoint.sol';
import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';
import {IDisapproveAction} from 'interfaces/actions-builders/IDisapproveAction.sol';

contract DisapproveAction is IDisapproveAction {
  /// @inheritdoc IDisapproveAction
  address public immutable SAFE_ENTRYPOINT;

  /// @inheritdoc IDisapproveAction
  address public immutable ACTIONS_BUILDER;

  /**
   * @notice Constructor that sets up the DisapproveAction contract
   * @param _safeEntrypoint The SafeEntrypoint contract address
   * @param _actionsBuilder The actions builder contract address
   */
  constructor(address _safeEntrypoint, address _actionsBuilder) {
    SAFE_ENTRYPOINT = _safeEntrypoint;
    ACTIONS_BUILDER = _actionsBuilder;
  }

  // ~~~ ACTIONS METHODS ~~~

  /// @inheritdoc IActionsBuilder
  function getActions() external view returns (Action[] memory _actions) {
    _actions = new Action[](1);
    _actions[0] = Action({
      target: SAFE_ENTRYPOINT,
      data: abi.encodeCall(ISafeEntrypoint.approveActionsBuilder, (ACTIONS_BUILDER, 0)),
      value: 0
    });
  }
}
