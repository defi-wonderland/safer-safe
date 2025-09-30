// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';

abstract contract ActionsBuilder is IActionsBuilder {
  /// @inheritdoc IActionsBuilder
  address public immutable PARENT;

  /**
   * @notice Constructor that sets up the parent.
   * @param _parent The parent address. Parent can be a factory or an action hub.
   */
  constructor(address _parent) {
    PARENT = _parent;
  }

  /// @inheritdoc IActionsBuilder
  function getActions() external view virtual returns (Action[] memory _actions);
}
