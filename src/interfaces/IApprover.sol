// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ISafe} from '@safe-smart-account/interfaces/ISafe.sol';
import {ICanonGuard} from 'src/interfaces/ICanonGuard.sol';

interface IApprover {
  /**
   * @notice Emitted when a transaction is approved
   * @param _actionBuilder The address of the action builder
   * @param _safeNonce The nonce of the Safe transaction
   * @param _txHash The hash of the transaction
   */
  event TxApproved(address _actionBuilder, uint256 _safeNonce, bytes32 _txHash);

  /**
   * @notice Emitted when the sender is not the EOA itself
   */
  error InvalidSender();

  /**
   * @notice Approves a transaction with the given action builder and safe nonce
   * @param _actionBuilder The address of the action builder
   * @param _safeNonce The nonce of the Safe transaction
   */
  function approveTx(address _actionBuilder, uint256 _safeNonce) external;

  /**
   * @notice Returns the address of the CanonGuard contract
   * @return _canonGuard The address of the CanonGuard contract
   */
  function CANON_GUARD() external view returns (ICanonGuard _canonGuard);

  /**
   * @notice Returns the address of the Safe contract
   * @return _safe The address of the Safe contract
   */
  function SAFE() external view returns (ISafe _safe);
}
