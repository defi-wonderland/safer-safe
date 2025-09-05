// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';

abstract contract ActionsBuilder is IActionsBuilder {
  /// @inheritdoc IActionsBuilder
  address public immutable PARENT;

  /// @inheritdoc IActionsBuilder
  bool public constant IS_BUILDER = true;

  /**
   * @notice Constructor that sets up the parent
   * @param _parent The parent address
   */
  constructor(address _parent) {
    PARENT = _parent;
  }

  /// @inheritdoc IActionsBuilder
  function getActions() external view virtual returns (Action[] memory _actions);
}
