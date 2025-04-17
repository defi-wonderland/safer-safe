// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.29;

import {ISafe} from '@safe-smart-account/interfaces/ISafe.sol';

interface ISafeManageable {
  function SAFE() external view returns (ISafe _safe);

  // ~~~ ERRORS ~~~

  error NotAuthorized();
}
