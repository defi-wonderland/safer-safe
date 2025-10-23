// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ActionTarget, BaseHandlers} from './BaseHandlers.sol';

abstract contract HandlersEverclearTokenConversion is BaseHandlers {
  function handler_queueEverclearTokenConversion(uint256 _approvalDuration, uint256 _amount) public {
    _amount = bound(_amount, MIN_AMOUNT, MAX_AMOUNT);

    address builder = everclearTokenConversionFactory.createEverclearTokenConversion(
      address(actionTarget), // lockbox
      address(actionTarget) // next token
    );

    _createApproveAndQueueBuilder(builder, ActionsBuilderType.EVERCLEAR_TOKEN_CONVERSION, _approvalDuration);
  }
}
