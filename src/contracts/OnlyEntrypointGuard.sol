// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.29;

import {BaseTransactionGuard} from '@safe-smart-account/base/GuardManager.sol';
import {Enum} from '@safe-smart-account/libraries/Enum.sol';
import {IOnlyEntrypointGuard} from 'interfaces/IOnlyEntrypointGuard.sol';

/**
 * @title OnlyEntrypointGuard
 * @notice Guard that ensures transactions are either executed through the entrypoint or by a high-threshold multisig signer
 */
contract OnlyEntrypointGuard is BaseTransactionGuard, IOnlyEntrypointGuard {
  /// @inheritdoc IOnlyEntrypointGuard
  uint256 public constant PRE_VALIDATED_SIGNATURE_TYPE = 0x01;

  /// @inheritdoc IOnlyEntrypointGuard
  address public immutable ENTRYPOINT;

  /// @inheritdoc IOnlyEntrypointGuard
  uint256 public immutable MIN_SIGNERS;

  /**
   * @notice Constructor that sets up the guard
   * @param _entrypoint The address of the Safe Entrypoint contract
   * @param _minSigners The minimum number of signers required for emergency override
   */
  constructor(address _entrypoint, uint256 _minSigners) {
    ENTRYPOINT = _entrypoint;
    MIN_SIGNERS = _minSigners;
  }

  /**
   * @notice Checks if a transaction is allowed to be executed
   * @dev This function is called before a transaction is executed
   * @param _to The address the transaction is being sent to
   * @param _value The value being sent with the transaction
   * @param _data The data being sent with the transaction
   * @param _operation The operation being performed (Call or DelegateCall)
   * @param _safeTxGas The gas to use for the transaction
   * @param _baseGas The base gas to use for the transaction
   * @param _gasPrice The gas price to use for the transaction
   * @param _gasToken The token to use for gas
   * @param _refundReceiver The address to receive any refunds
   * @param _signatures The signatures for the transaction
   * @param _msgSender The address of the sender of the transaction
   */
  function checkTransaction(
    address _to,
    uint256 _value,
    bytes memory _data,
    Enum.Operation _operation,
    uint256 _safeTxGas,
    uint256 _baseGas,
    uint256 _gasPrice,
    address _gasToken,
    address payable _refundReceiver,
    bytes memory _signatures,
    address _msgSender
  ) external override {
    // Allow transactions from the entrypoint
    if (_msgSender == ENTRYPOINT) {
      return;
    }

    // Validate signature format - only allow pre-approved hash signatures
    if (!_isValidSignatureFormat(_signatures)) {
      revert InvalidSignatureFormat();
    }

    // Check if the transaction has enough signers for emergency override
    uint256 _signerCount = _countSigners(_signatures);
    if (_signerCount >= MIN_SIGNERS) {
      return;
    }

    // If we get here, the transaction is not allowed
    revert TransactionNotAllowed();
  }

  /**
   * @notice Checks if a transaction is allowed to be executed after execution
   * @dev This function is called after a transaction is executed
   * @param _txHash The hash of the transaction
   * @param _success Whether the transaction was successful
   */
  function checkAfterExecution(bytes32 _txHash, bool _success) external override {
    // No post-execution checks needed
  }

  /**
   * @notice Counts the number of signers in a transaction
   * @param _signatures The signatures for the transaction
   * @return _count The number of signers
   */
  function _countSigners(bytes memory _signatures) internal pure returns (uint256 _count) {
    // Each signature is 65 bytes (r: 32 bytes, s: 32 bytes, v: 1 byte)
    return _signatures.length / 65;
  }

  /**
   * @notice Validates that all signatures are pre-approved hash signatures
   * @param _signatures The signatures to validate
   * @return _isValid Whether all signatures are pre-approved hash signatures
   */
  function _isValidSignatureFormat(bytes memory _signatures) internal pure returns (bool _isValid) {
    // Check if the signatures length is a multiple of 65 bytes
    if (_signatures.length % 65 != 0) {
      return false;
    }

    // Check each signature
    for (uint256 i = 0; i < _signatures.length; i += 65) {
      // Get the signature type (last byte of each 65-byte signature)
      uint8 _signatureType = uint8(_signatures[i + 64]);

      // Only allow pre-approved hash signatures (type 0x01)
      if (_signatureType != PRE_VALIDATED_SIGNATURE_TYPE) {
        return false;
      }
    }

    return true;
  }
}
