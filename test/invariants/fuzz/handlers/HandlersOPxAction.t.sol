// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ActionTarget, BaseHandlers} from './BaseHandlers.sol';

abstract contract HandlersOPxAction is BaseHandlers {
  function handler_queueOPxAction(uint256 _approvalDuration, uint256 _amount) public {
    _approvalDuration = bound(_approvalDuration, 1, 1000);
    _amount = bound(_amount, 1, 1_000_000);

    address actionsBuilder = opxActionFactory.createOPxAction(
      address(actionTarget) // opx token (actionTarget acts as OPx token)
    );

    vm.prank(address(safe));
    try canonGuard.approveActionsBuilderOrHub(actionsBuilder, _approvalDuration) {
      vm.prank(signers[0]);
      canonGuard.queueTransaction(actionsBuilder);

      bytes32 _safeTxHash = canonGuard.getSafeTransactionHash(actionsBuilder);

      ghost_hashToActionsBuilder[_safeTxHash] = actionsBuilder;
      ghost_hashes.push(_safeTxHash);
      ghost_timestampOfActionQueued[_safeTxHash] = block.timestamp;
      ghost_actionsBuilderType[actionsBuilder] = ActionsBuilderType.OPX_ACTION;
    } catch {
      assertGt(_approvalDuration, canonGuard.MAX_APPROVAL_DURATION());
    }
  }
}
