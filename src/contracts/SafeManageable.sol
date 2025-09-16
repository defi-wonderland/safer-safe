// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ISafe} from '@safe-smart-account/interfaces/ISafe.sol';
import {ISafeManageable} from 'interfaces/ISafeManageable.sol';

/**
 * @title SafeManageable
 * @notice Abstract contract that provides common functionality for managing a Safe
 */
abstract contract SafeManageable is ISafeManageable {
  // ~~~ STORAGE ~~~

  /// @inheritdoc ISafeManageable
  ISafe public immutable SAFE;

  // ~~~ MODIFIERS ~~~

  /**
   * @notice Modifier that checks if the caller is the Safe contract
   */
  modifier isSafe() {
    if (msg.sender != address(SAFE)) revert NotSafe();
    _;
  }

  /**
   * @notice Modifier that checks if the caller is a Safe owner
   */
  modifier isSafeOwner() {
    if (!SAFE.isOwner(msg.sender)) revert NotSafeOwner();
    _;
  }

  // ~~~ CONSTRUCTOR ~~~

  /**
   * @notice Constructor that sets up the Safe contract
   * @param _safe The Gnosis Safe contract address
   */
  constructor(address _safe) {
    SAFE = ISafe(_safe);
  }
}
