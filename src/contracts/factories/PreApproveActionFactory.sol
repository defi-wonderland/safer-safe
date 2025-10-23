// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {PreApproveAction} from 'contracts/actions-builders/PreApproveAction.sol';
import {Factory} from 'contracts/factories/Factory.sol';
import {IPreApproveActionFactory} from 'interfaces/factories/IPreApproveActionFactory.sol';

/**
 * @title PreApproveActionFactory
 * @notice Contract that deploys PreApproveAction contracts
 */
contract PreApproveActionFactory is IPreApproveActionFactory, Factory {
  // ~~~ FACTORY METHODS ~~~

  /// @inheritdoc IPreApproveActionFactory
  function createPreApproveAction(
    address _actionsBuilder,
    uint256 _approvalDuration
  ) external returns (address _preApproveAction) {
    _preApproveAction = address(new PreApproveAction(address(this), _actionsBuilder, _approvalDuration));

    _children[_preApproveAction] = true;

    emit PreApproveActionCreated(_preApproveAction, _actionsBuilder, _approvalDuration, msg.sender);
  }
}
