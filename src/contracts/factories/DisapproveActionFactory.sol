// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {DisapproveAction} from 'contracts/actions-builders/DisapproveAction.sol';
import {IDisapproveActionFactory} from 'interfaces/factories/IDisapproveActionFactory.sol';

/**
 * @title DisapproveActionFactory
 * @notice Contract that deploys DisapproveAction contracts
 */
contract DisapproveActionFactory is IDisapproveActionFactory {
  // ~~~ FACTORY METHODS ~~~

  /// @inheritdoc IDisapproveActionFactory
  function createDisapproveAction(
    address _safeEntrypoint,
    address _actionsBuilder
  ) external returns (address _disapproveAction) {
    _disapproveAction = address(new DisapproveAction(_safeEntrypoint, _actionsBuilder));
  }
}
