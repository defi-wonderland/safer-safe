// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {DisapproveAction} from 'contracts/actions-builders/DisapproveAction.sol';
import {Factory} from 'contracts/factories/Factory.sol';
import {IDisapproveActionFactory} from 'interfaces/factories/IDisapproveActionFactory.sol';

/**
 * @title DisapproveActionFactory
 * @notice Contract that deploys DisapproveAction contracts
 */
contract DisapproveActionFactory is IDisapproveActionFactory, Factory {
  // ~~~ FACTORY METHODS ~~~

  /// @inheritdoc IDisapproveActionFactory
  function createDisapproveAction(
    address _canonGuard,
    address _actionsBuilder
  ) external returns (address _disapproveAction) {
    _disapproveAction = address(new DisapproveAction(address(this), _canonGuard, _actionsBuilder));

    _children[_disapproveAction] = true;
  }
}
