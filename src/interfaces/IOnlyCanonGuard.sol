// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ITransactionGuard} from '@safe-smart-account/base/GuardManager.sol';

/**
 * @title IOnlyCanonGuard
 * @notice Interface for the OnlyCanonGuard contract
 */
interface IOnlyCanonGuard is ITransactionGuard {
  // ~~~ ERRORS ~~~

  /**
   * @notice Thrown when a transaction is attempted by an unauthorized sender
   * @param _sender The unauthorized sender address
   */
  error UnauthorizedSender(address _sender);
}
