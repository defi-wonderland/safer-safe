// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {SafeEntrypoint} from 'contracts/SafeEntrypoint.sol';

import {ISafeEntrypointFactory} from 'interfaces/factories/ISafeEntrypointFactory.sol';

contract SafeEntrypointFactory is ISafeEntrypointFactory {
  address public immutable MULTI_SEND_CALL_ONLY;

  constructor(address _multiSend) {
    MULTI_SEND_CALL_ONLY = _multiSend;
  }

  function createSafeEntrypoint(address _safe) external returns (address) {
    return address(new SafeEntrypoint(_safe, MULTI_SEND_CALL_ONLY));
  }
}
