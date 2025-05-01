// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

interface ICappedTokenTransfersFactory {
  function createCappedTokenTransfers(
    address _safe,
    address _token,
    uint256 _cap,
    uint256 _epochLength
  ) external returns (address);
}
