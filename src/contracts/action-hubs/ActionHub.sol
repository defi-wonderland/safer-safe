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
   * @notice Deploys a new actions builder with deterministic address. Reverts if the action builder already exists.
   * @param _initCode The init code of the new actions builder
   * @param _salt The salt used to deploy the new actions builder
   * @return _actionsBuilder The address of the new actions builder
   */
  function _createNewActionsBuilder(bytes memory _initCode, bytes32 _salt) internal returns (address _actionsBuilder) {
    // Deploy with create3 to have deterministic addresses, if the child already exists, it will revert
    _actionsBuilder = CREATE3.deployDeterministic(_initCode, _salt);

    _actionsBuilders[_actionsBuilder] = true;

    emit NewActionsBuilderCreated(_actionsBuilder, _initCode, _salt);
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
