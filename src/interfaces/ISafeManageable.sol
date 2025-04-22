// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ISafe} from '@safe-smart-account/interfaces/ISafe.sol';

/**
 * @title ISafeManageable
 * @notice Interface for the SafeManageable contract
 */
interface ISafeManageable {
  // ~~~ STORAGE METHODS ~~~

  /**
   * @notice Gets the Safe contract
   * @return _safe The Gnosis Safe contract address
   */
  function SAFE() external view returns (ISafe _safe);

  // ~~~ ERRORS ~~~

  /**
   * @notice Thrown when the caller is not a Safe owner
   */
  error NotAuthorized();
}
