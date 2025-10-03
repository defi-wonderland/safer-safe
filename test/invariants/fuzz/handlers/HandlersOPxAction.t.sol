// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ActionTarget, BaseHandlers} from './BaseHandlers.sol';

abstract contract HandlersOPxAction is BaseHandlers {
  function handler_queueOPxAction(uint256 _approvalDuration, uint256 _amount) public {
    _amount = bound(_amount, MIN_AMOUNT, MAX_AMOUNT);

    address builder = opxActionFactory.createOPxAction(address(actionTarget));
    _createApproveAndQueueBuilder(builder, ActionsBuilderType.OPX_ACTION, _approvalDuration);
  }
}
