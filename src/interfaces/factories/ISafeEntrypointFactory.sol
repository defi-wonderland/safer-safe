// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

interface ISafeEntrypointFactory {
  function MULTI_SEND_CALL_ONLY() external view returns (address _multiSendCallOnly);

  function createSafeEntrypoint(
    address _safe,
    uint256 _shortExecutionDelay,
    uint256 _longExecutionDelay
  ) external returns (address);
}
