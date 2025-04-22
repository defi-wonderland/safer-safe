// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

interface IAllowanceClaimorFactory {
  function createAllowanceClaimor(
    address _safe,
    address _token,
    address _tokenOwner,
    address _tokenRecipient
  ) external returns (address);
}
