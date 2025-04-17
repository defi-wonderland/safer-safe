// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.29;

interface ISafeEntrypointFactory {
  function MULTI_SEND_CALL_ONLY() external view returns (address _multiSendCallOnly);

  function createSafeEntrypoint(address _safe) external returns (address);
}
