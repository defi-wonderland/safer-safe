// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';

abstract contract ActionBuilder is IActionsBuilder {
  /// @inheritdoc IActionsBuilder
  address public immutable FACTORY;

  /// @inheritdoc IActionsBuilder
  function getActions() external view virtual returns (Action[] memory _actions);
}
