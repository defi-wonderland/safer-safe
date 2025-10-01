// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ActionTarget, BaseHandlers} from './BaseHandlers.sol';

abstract contract HandlersEverclearTokenConversion is BaseHandlers {
  function handler_queueEverclearTokenConversion(uint256 _approvalDuration, uint256 _amount) public {
    _approvalDuration = bound(_approvalDuration, 1, 1000);
    _amount = bound(_amount, 1, 1_000_000);

    address actionsBuilder = everclearTokenConversionFactory.createEverclearTokenConversion(
      address(actionTarget), // lockbox - will track call to deposit()
      address(actionTarget) // next token - will track call to approve()
    );

    vm.prank(address(safe));
    try canonGuard.approveActionsBuilderOrHub(actionsBuilder, _approvalDuration) {
      vm.prank(signers[0]);
      canonGuard.queueTransaction(actionsBuilder);

      bytes32 _safeTxHash = canonGuard.getSafeTransactionHash(actionsBuilder);

      ghost_hashToActionsBuilder[_safeTxHash] = actionsBuilder;
      ghost_hashes.push(_safeTxHash);
      ghost_timestampOfActionQueued[_safeTxHash] = block.timestamp;
      ghost_actionsBuilderType[actionsBuilder] = ActionsBuilderType.EVERCLEAR_TOKEN_CONVERSION;
    } catch {
      assertGt(_approvalDuration, canonGuard.MAX_APPROVAL_DURATION());
    }
  }
}
