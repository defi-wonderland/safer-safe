// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import {IActions} from '../interfaces/IActions.sol';
import {ISafe} from '../interfaces/ISafe.sol';

abstract contract SafeManageable {
  ISafe public immutable SAFE;

  error NotAuthorized();

  constructor(address _safe) {
    SAFE = ISafe(_safe);
  }

  modifier isMsig() {
    if (msg.sender != address(SAFE)) revert NotAuthorized();
    _;
  }

  modifier isAuthorized() {
    if (!SAFE.isOwner(msg.sender)) revert NotAuthorized();
    _;
  }
}
