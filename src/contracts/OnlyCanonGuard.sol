// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {BaseTransactionGuard} from '@safe-smart-account/base/GuardManager.sol';
import {ITransactionGuard} from '@safe-smart-account/base/GuardManager.sol';
import {Enum} from '@safe-smart-account/libraries/Enum.sol';
import {IOnlyCanonGuard} from 'interfaces/IOnlyCanonGuard.sol';

/**
 * @title OnlyCanonGuard
 * @notice Guard that ensures transactions are executed through the canon guard
 */
// solhint-disable-next-line payable-fallback
abstract contract OnlyCanonGuard is BaseTransactionGuard, IOnlyCanonGuard {
  // ~~~ FALLBACK ~~~

  /**
   * @notice Fallback to avoid issues in case of a Safe upgrade
   * @dev The expected check method might change and then the Safe would be locked
   */
  fallback() external {}

  // ~~~ GUARD METHODS ~~~

  /// @inheritdoc ITransactionGuard
  function checkTransaction(
    address, /* _to */
    uint256, /* _value */
    bytes memory, /* _data */
    Enum.Operation, /* _operation */
    uint256, /* _safeTxGas */
    uint256, /* _baseGas */
    uint256, /* _gasPrice */
    address, /* _gasToken */
    address payable, /*  _refundReceiver */
    bytes memory, /* _signatures */
    address _msgSender
  ) external view virtual override {
    // Allow transactions from the canon guard or emergency caller
    if (_msgSender != address(this)) {
      revert UnauthorizedSender(_msgSender);
    }
  }

  /// @inheritdoc ITransactionGuard
  function checkAfterExecution(
    bytes32,
    /* _hash */
    bool /* _success */
  ) external pure virtual override {
    // No post-execution checks needed
  }
}
