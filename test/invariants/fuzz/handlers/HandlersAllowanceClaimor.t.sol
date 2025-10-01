// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ActionTarget, BaseHandlers, CanonGuard, CanonGuardFactory, Safe} from './BaseHandlers.sol';

abstract contract HandlersAllowanceClaimor is BaseHandlers {
  function handler_queueAllowanceClaimor(uint256 _approvalDuration) public {
    _approvalDuration = bound(_approvalDuration, 1, 1000);

    address _actionsBuilder = allowanceClaimorFactory.createAllowanceClaimor(
      address(actionTarget), // token
      TOKEN_SENDER, // token owner
      TOKEN_RECIPIENT // token recipient
    );

    vm.prank(signers[0]);
    canonGuard.queueTransaction(_actionsBuilder);

    bytes32 _safeTxHash = canonGuard.getSafeTransactionHash(_actionsBuilder);

    ghost_hashToActionsBuilder[_safeTxHash] = _actionsBuilder;
    ghost_hashes.push(_safeTxHash);
    ghost_timestampOfActionQueued[_safeTxHash] = block.timestamp;
    ghost_actionsBuilderType[_actionsBuilder] = ActionsBuilderType.ALLOWANCE_CLAIMOR;
  }
}
