// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ActionTarget, BaseHandlers} from './BaseHandlers.sol';

import {SimpleActionsFactory} from 'contracts/factories/SimpleActionsFactory.sol';
import {ISimpleActions} from 'interfaces/actions-builders/ISimpleActions.sol';

/// @title HandlersSimpleActions
/// @notice Handler for SimpleActions action builders
/// @dev Tests invariants for multi-action transactions (deposit + transfer)
abstract contract HandlersSimpleActions is BaseHandlers {
  /// @notice Queue a SimpleActions action builder with multiple actions
  /// @dev Creates a builder with deposit and transfer actions
  /// @param _approvalDuration Duration of approval (bounded to reasonable values)
  function handler_queueSimpleAction(uint256 _approvalDuration) public {
    ISimpleActions.SimpleAction[] memory actions = new ISimpleActions.SimpleAction[](2);
    actions[0] =
      ISimpleActions.SimpleAction({target: address(actionTarget), signature: 'deposit()', data: bytes(''), value: 0});
    actions[1] = ISimpleActions.SimpleAction({
      target: address(actionTarget),
      signature: 'transfer(address,uint256)',
      data: abi.encode(TOKEN_RECIPIENT, AMOUNT),
      value: 0
    });

    address builder = simpleActionsFactory.createSimpleActions(actions);
    _createApproveAndQueueBuilder(builder, ActionsBuilderType.SIMPLE_ACTIONS, _approvalDuration);
  }
}
