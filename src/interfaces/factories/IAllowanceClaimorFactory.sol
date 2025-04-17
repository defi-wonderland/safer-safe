// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.29;

interface IAllowanceClaimorFactory {
  function createAllowanceClaimor(
    address _safe,
    address _token,
    address _tokenOwner,
    address _tokenRecipient
  ) external returns (address);
}
