// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IActionHub} from 'interfaces/action-hubs/IActionHub.sol';
import {CREATE3} from 'solady/utils/CREATE3.sol';

abstract contract ActionHub is IActionHub {
  /// @inheritdoc IActionHub
  address public immutable FACTORY;

  /**
   * @notice The mapping of action builders. Returns true if the action builder is a child of the actionHub.
   */
  mapping(address _actionBuilder => bool _exists) internal _actionBuilders;

  /// @inheritdoc IActionHub
  function isChild(address _actionBuilder) external view returns (bool _exists) {
    _exists = _isChild(_actionBuilder);
  }

  /**
   * @notice Creates a new action builder
   * @param _initCode The init code of the new action builder
   * @param _salt The salt used to deploy the new action builder
   * @return _actionBuilder The address of the new action builder
   */
  function _createNewActionBuilder(bytes memory _initCode, bytes32 _salt) internal returns (address _actionBuilder) {
    // Deploy with create3 to have deterministic addresses, if the child already exists, it will revert
    _actionBuilder = CREATE3.deployDeterministic(_initCode, _salt);

    _actionBuilders[_actionBuilder] = true;

    emit NewActionBuilderCreated(_actionBuilder, _initCode, _salt);
  }

  /**
   * @notice Returns true if the action builder is a child of the actionHub
   * @param _child The address of the action builder to check
   * @return _exists True if the action builder is a child of the actionHub, false otherwise
   */
  function _isChild(address _child) internal view returns (bool _exists) {
    _exists = _actionBuilders[_child];
  }
}
