// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.29;

import {ISafe} from '../interfaces/ISafe.sol';

abstract contract SafeManageable {
  ISafe public immutable SAFE;

  error NotAuthorized();

  modifier isMsig() {
    // TODO: uncomment after making the test call from the Safe
    // if (msg.sender != address(SAFE)) revert NotAuthorized();
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
