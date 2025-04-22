// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.29;

import {ISafeManageable} from 'interfaces/ISafeManageable.sol';

import {ISafe} from '@safe-smart-account/interfaces/ISafe.sol';

/**
 * @title SafeManageable
 * @notice Abstract contract that provides common functionality for managing a Safe
 */
abstract contract SafeManageable is ISafeManageable {
  /// @inheritdoc ISafeManageable
  ISafe public immutable SAFE;

  /**
   * @notice Modifier that checks if the caller is the Safe contract
   */
  modifier isSafe() {
    if (msg.sender != address(SAFE)) revert NotSafeOwner();
    _;
  }

  /**
   * @notice Modifier that checks if the caller is a Safe owner
   */
  modifier isSafeOwner() {
    if (!SAFE.isOwner(msg.sender)) revert NotSafeOwner();
    _;
  }

  /**
   * @notice Constructor that sets up the Safe contract
   * @param _safe The Gnosis Safe contract address
   */
  constructor(address _safe) {
    SAFE = ISafe(_safe);
  }
}
