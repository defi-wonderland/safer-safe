// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {BaseHandlers} from './BaseHandlers.sol';

/// @title HandlersAllowanceClaimor
/// @notice Handler for AllowanceClaimor action builders
/// @dev Tests invariants related to token allowance claiming
abstract contract HandlersAllowanceClaimor is BaseHandlers {
  /// @notice Queue an AllowanceClaimor action builder
  /// @dev Creates and queues an action builder that claims tokens via allowance
  /// @param _approvalDuration Duration of approval (bounded to reasonable values)
  function handler_queueAllowanceClaimor(uint256 _approvalDuration) public {
    address builder =
      allowanceClaimorFactory.createAllowanceClaimor(address(actionTarget), TOKEN_SENDER, TOKEN_RECIPIENT);
    _createApproveAndQueueBuilder(builder, ActionsBuilderType.ALLOWANCE_CLAIMOR, _approvalDuration);
  }
}
