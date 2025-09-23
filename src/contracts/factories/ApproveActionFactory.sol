// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ApproveAction} from 'contracts/actions-builders/ApproveAction.sol';
import {Factory} from 'contracts/factories/Factory.sol';
import {IApproveActionFactory} from 'interfaces/factories/IApproveActionFactory.sol';

/**
 * @title ApproveActionFactory
 * @notice Contract that deploys ApproveAction contracts
 */
contract ApproveActionFactory is IApproveActionFactory, Factory {
  // ~~~ FACTORY METHODS ~~~

  /// @inheritdoc IApproveActionFactory
  function createApproveAction(
    address _actionsBuilder,
    uint256 _approvalDuration
  ) external returns (address _approveAction) {
    _approveAction = address(new ApproveAction(address(this), _actionsBuilder, _approvalDuration));

    _children[_approveAction] = true;
  }
}
