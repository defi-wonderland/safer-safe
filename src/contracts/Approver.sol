// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ISafe} from '@safe-smart-account/interfaces/ISafe.sol';
import {IApprover} from 'src/interfaces/IApprover.sol';
import {ICanonGuard} from 'src/interfaces/ICanonGuard.sol';

contract Approver is IApprover {
  /// @inheritdoc IApprover
  ICanonGuard public immutable CANON_GUARD;

  /// @inheritdoc IApprover
  ISafe public immutable SAFE;

  /**
   * @notice Constructor of the contract
   * @param _canonGuard The address of the CanonGuard contract
   */
  constructor(address _canonGuard) {
    CANON_GUARD = ICanonGuard(_canonGuard);
    SAFE = CANON_GUARD.SAFE();
  }

  /// @inheritdoc IApprover
  function approveTx(address _actionBuilder, uint256 _safeNonce) external {
    if (msg.sender != address(this)) revert InvalidSender();

    bytes32 _safeTxHash = CANON_GUARD.getSafeTransactionHash(_actionBuilder, _safeNonce);
    SAFE.approveHash(_safeTxHash);

    emit TxApproved(_actionBuilder, _safeNonce, _safeTxHash);
  }
}
