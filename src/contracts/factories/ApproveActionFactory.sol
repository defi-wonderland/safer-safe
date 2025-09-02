// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ApproveAction} from 'contracts/actions-builders/ApproveAction.sol';
import {IApproveActionFactory} from 'interfaces/factories/IApproveActionFactory.sol';

/**
 * @title ApproveActionFactory
 * @notice Contract that deploys ApproveAction contracts
 */
contract ApproveActionFactory is IApproveActionFactory {
  // ~~~ FACTORY METHODS ~~~

  /// @inheritdoc IApproveActionFactory
  function createApproveAction(
    address _canonGuard,
    address _actionsBuilder,
    uint256 _approvalDuration
  ) external returns (address _approveAction) {
    _approveAction = address(new ApproveAction(_canonGuard, _actionsBuilder, _approvalDuration));
  }
}
