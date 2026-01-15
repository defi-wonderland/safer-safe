// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {BaseHandlers} from './BaseHandlers.sol';

import {IArbitraryActions} from 'interfaces/actions-builders/IArbitraryActions.sol';

/// @title HandlersArbitraryActions
/// @notice Handler for ArbitraryActions action builders
/// @dev Tests invariants for multi-action transactions (deposit + transfer)
abstract contract HandlersArbitraryActions is BaseHandlers {
  /// @notice Queue an ArbitraryActions action builder with multiple actions
  /// @dev Creates a builder with deposit and transfer actions
  /// @param _approvalDuration Duration of approval (bounded to reasonable values)
  function handler_queueArbitraryAction(uint256 _approvalDuration) public {
    IArbitraryActions.ArbitraryAction[] memory actions = new IArbitraryActions.ArbitraryAction[](2);
    actions[0] = IArbitraryActions.ArbitraryAction({
      target: address(actionTarget),
      signature: 'deposit()',
      data: abi.encodePacked(bytes4(keccak256(bytes('deposit()'))), abi.encode(bytes(''))),
      value: 0
    });
    actions[1] = IArbitraryActions.ArbitraryAction({
      target: address(actionTarget),
      signature: 'transfer(address,uint256)',
      data: abi.encodePacked(
        bytes4(keccak256(bytes('transfer(address,uint256)'))), abi.encode(TOKEN_RECIPIENT, AMOUNT)
      ),
      value: 0
    });

    address builder = arbitraryActionsFactory.createArbitraryActions(actions);
    _createApproveAndQueueBuilder(builder, ActionsBuilderType.SIMPLE_ACTIONS, _approvalDuration);
  }
}
