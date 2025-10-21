// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IActionHub} from 'interfaces/action-hubs/IActionHub.sol';
import {CREATE3} from 'solady/utils/CREATE3.sol';

abstract contract ActionHub is IActionHub {
  /// @inheritdoc IActionHub
  address public immutable PARENT;

  /**
   * @notice The mapping of actions builders. Returns true if the actions builder is a child of the actionHub.
   */
  mapping(address _actionsBuilder => bool _exists) internal _actionsBuilders;

  /**
   * @notice Constructor that sets up the parent
   * @param _parent The parent address
   */
  constructor(address _parent) {
    PARENT = _parent;
  }

  /// @inheritdoc IActionHub
  function isHubChild(address _actionsBuilder) external view returns (bool _exists) {
    _exists = _isHubChild(_actionsBuilder);
  }

  /**
   * @notice Saves the actions builder as a child of the actionHub.
   * @param _actionsBuilder The address of the actions builder to save as a child
   */
  function _saveNewActionsBuilder(address _actionsBuilder) internal {
    _actionsBuilders[_actionsBuilder] = true;

    emit NewActionsBuilderSaved(_actionsBuilder);
  }

  /**
   * @notice Returns true if the actions builder is a child of the actionHub
   * @param _child The address of the actions builder to check
   * @return _exists True if the actions builder is a child of the actionHub, false otherwise
   */
  function _isHubChild(address _child) internal view returns (bool _exists) {
    _exists = _actionsBuilders[_child];
  }
}
