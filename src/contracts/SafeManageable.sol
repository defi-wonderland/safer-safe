// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.29;

import {ISafeManageable} from 'interfaces/ISafeManageable.sol';

import {ISafe} from '@safe-smart-account/interfaces/ISafe.sol';

abstract contract SafeManageable is ISafeManageable {
  ISafe public immutable SAFE;

  modifier isMsig() {
    if (msg.sender != address(SAFE)) revert NotAuthorized();
    _;
  }

  modifier isAuthorized() {
    if (!SAFE.isOwner(msg.sender)) revert NotAuthorized();
    _;
  }

  constructor(address _safe) {
    SAFE = ISafe(_safe);
  }
}
