// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IFactory} from 'interfaces/factories/IFactory.sol';

abstract contract Factory is IFactory {
  /**
   * @notice Mapping of contracts created by the factory
   */
  mapping(address _children => bool _exists) internal _children;

  // ~~~ FUNCTIONS ~~~

  /// @inheritdoc IFactory
  function isChild(address _contract) external view returns (bool _isChild) {
    _isChild = _children[_contract];
  }
}
