// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {SafeManageable} from 'contracts/SafeManageable.sol';

contract SafeManageableForTest is SafeManageable {
  constructor(address _safe) SafeManageable(_safe) {}

  function testIsSafeModifier() external isSafe {}

  function testIsSafeOwnerModifier() external isSafeOwner {}
}
