// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ISafe} from '@safe-smart-account/interfaces/ISafe.sol';
import {ICanonGuard} from 'src/interfaces/ICanonGuard.sol';

interface IApprover {
  /**
   * @notice Emitted when a transaction is approved
   * @param _actionsBuilder The address of the actions buider
   * @param _safeNonce The nonce of the Safe transaction
   * @param _txHash The hash of the transaction
   */
  event TxApproved(address _actionsBuilder, uint256 _safeNonce, bytes32 _txHash);

  /**
   * @notice Emitted when the sender is not the EOA itself
   */
  error InvalidSender();

  /**
   * @notice Approves a transaction with the given actions buider and safe nonce
   * @param _actionsBuilder The address of the actions buider
   * @param _safeNonce The nonce of the Safe transaction
   */
  function approveTx(address _actionsBuilder, uint256 _safeNonce) external;

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
