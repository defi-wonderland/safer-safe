// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.29;

import {SafeEntrypoint} from '../SafeEntrypoint.sol';

contract SafeEntrypointFactory {
  address public immutable MULTI_SEND_CALL_ONLY;

  constructor(address _multiSend) {
    MULTI_SEND_CALL_ONLY = _multiSend;
  }

  function createSafeEntrypoint(address _safe) external returns (address) {
    return address(new SafeEntrypoint(_safe, MULTI_SEND_CALL_ONLY));
  }
}
