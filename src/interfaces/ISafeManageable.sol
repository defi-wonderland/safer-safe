// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ISafe} from '@safe-smart-account/interfaces/ISafe.sol';

/**
 * @title ISafeManageable
 * @notice Interface for the SafeManageable abstract contract
 */
interface ISafeManageable {
  // ~~~ ERRORS ~~~

  /**
   * @notice Thrown when the caller is not the Safe contract
   */
  error NotSafe();

  /**
   * @notice Thrown when the caller is not a Safe owner
   */
  error NotSafeOwner();

  // ~~~ STORAGE METHODS ~~~

  /**
   * @notice Gets the Safe contract
   * @return _safe The Gnosis Safe contract address
   */
  function SAFE() external view returns (ISafe _safe);
}
