// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import {AllowanceClaimor} from '../AllowanceClaimor.sol';

contract AllowanceClaimorFactory {
  function createAllowanceClaimor(
    address _token,
    address _tokenOwner,
    address _tokenRecipient
  ) external returns (address) {
    return address(new AllowanceClaimor(_token, _tokenOwner, _tokenRecipient));
  }
}
