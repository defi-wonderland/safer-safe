// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ActionTarget, BaseHandlers} from './BaseHandlers.sol';
import {ISimpleTransfers} from 'interfaces/actions-builders/ISimpleTransfers.sol';

/// @title HandlersSimpleTransfers
/// @notice Handler for SimpleTransfers action builders
/// @dev Tests invariants for single token transfer transactions
abstract contract HandlersSimpleTransfers is BaseHandlers {
  /// @notice Queue a SimpleTransfers action builder
  /// @dev Creates a builder for a simple token transfer action
  /// @param _approvalDuration Duration of approval (bounded to reasonable values)
  function handler_queueSimpleTransfers(uint256 _approvalDuration) public {
    ISimpleTransfers.TransferAction[] memory actions = new ISimpleTransfers.TransferAction[](1);
    actions[0] = ISimpleTransfers.TransferAction({token: address(actionTarget), to: TOKEN_RECIPIENT, amount: AMOUNT});

    address builder = simpleTransfersFactory.createSimpleTransfers(actions);
    _createApproveAndQueueBuilder(builder, ActionsBuilderType.SIMPLE_TRANSFERS, _approvalDuration);
  }
}
