// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {SafeEntrypoint} from 'contracts/SafeEntrypoint.sol';

import {ISafeEntrypointFactory} from 'interfaces/factories/ISafeEntrypointFactory.sol';

contract SafeEntrypointFactory is ISafeEntrypointFactory {
  address public immutable MULTI_SEND_CALL_ONLY;

  constructor(address _multiSend) {
    MULTI_SEND_CALL_ONLY = _multiSend;
  }

  function createSafeEntrypoint(
    address _safe,
    uint256 _shortExecutionDelay,
    uint256 _longExecutionDelay,
    uint256 _defaultTxExpirationTime
  ) external returns (address _safeEntrypoint) {
    _safeEntrypoint = address(
      new SafeEntrypoint(
        _safe, MULTI_SEND_CALL_ONLY, _shortExecutionDelay, _longExecutionDelay, _defaultTxExpirationTime
      )
    );
  }
}
