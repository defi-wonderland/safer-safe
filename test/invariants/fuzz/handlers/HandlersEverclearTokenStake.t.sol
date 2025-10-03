// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ActionTarget, BaseHandlers} from './BaseHandlers.sol';

abstract contract HandlersEverclearTokenStake is BaseHandlers {
  function handler_queueEverclearTokenStake(uint256 _approvalDuration, uint256 _lockTime) public {
    _lockTime = bound(_lockTime, MIN_LOCK_TIME, MAX_LOCK_TIME);
    _approvalDuration = bound(_approvalDuration, MIN_APPROVAL_DURATION, MAX_APPROVAL_DURATION);

    // EverclearTokenStake has complex external dependencies - handle failures gracefully
    try everclearTokenStakeFactory.createEverclearTokenStake(
      address(actionTarget),
      address(actionTarget),
      address(actionTarget),
      address(actionTarget),
      address(actionTarget),
      address(actionTarget),
      _lockTime
    ) returns (address builder) {
      if (!_tryApproveBuilder(builder, _approvalDuration)) return;

      vm.prank(signers[0]);
      try canonGuard.queueTransaction(builder) {
        bytes32 safeTxHash = canonGuard.getSafeTransactionHash(builder);
        _recordHash(safeTxHash, builder, ActionsBuilderType.EVERCLEAR_TOKEN_STAKE);
      } catch {
        // Queue might fail due to external calls in getActions()
      }
    } catch {
      // Builder creation might fail
    }
  }
}
