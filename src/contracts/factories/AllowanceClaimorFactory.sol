// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.29;

import {AllowanceClaimor} from 'contracts/actions/AllowanceClaimor.sol';

contract AllowanceClaimorFactory {
  function createAllowanceClaimor(
    address _safe,
    address _token,
    address _tokenOwner,
    address _tokenRecipient
  ) external returns (address) {
    return address(new AllowanceClaimor(_safe, _token, _tokenOwner, _tokenRecipient));
  }
}
