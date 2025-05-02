// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {BaseTransactionGuard} from '@safe-smart-account/base/GuardManager.sol';
import {Enum} from '@safe-smart-account/libraries/Enum.sol';
import {IOnlyEntrypointGuard} from 'interfaces/IOnlyEntrypointGuard.sol';

/**
 * @title OnlyEntrypointGuard
 * @notice Guard that ensures transactions are either executed through the entrypoint or by an emergency multisig contract
 */
contract OnlyEntrypointGuard is BaseTransactionGuard, IOnlyEntrypointGuard {
  /// @inheritdoc IOnlyEntrypointGuard
  uint256 public constant PRE_VALIDATED_SIGNATURE_TYPE = 0x01;

  /// @inheritdoc IOnlyEntrypointGuard
  address public immutable ENTRYPOINT;

  /// @inheritdoc IOnlyEntrypointGuard
  address public immutable EMERGENCY_CALLER;

  /// @inheritdoc IOnlyEntrypointGuard
  address public immutable MULTI_SEND_CALL_ONLY;

  /**
   * @notice Constructor that sets up the guard
   * @param _entrypoint The address of the Safe Entrypoint contract
   * @param _emergencyCaller The address of the emergency caller (can be a multisig or EOA)
   * @param _multiSendCallOnly The address of the MultiSendCallOnly contract
   */
  constructor(address _entrypoint, address _emergencyCaller, address _multiSendCallOnly) {
    ENTRYPOINT = _entrypoint;
    EMERGENCY_CALLER = _emergencyCaller;
    MULTI_SEND_CALL_ONLY = _multiSendCallOnly;
  }

  /**
   * @notice Checks if a transaction is allowed to be executed
   * @dev This function is called before a transaction is executed
   * @param _to The target address
   * @param _operation The operation type
   * @param _signatures The signatures for the transaction
   * @param _msgSender The address of the sender of the transaction
   */
  function checkTransaction(
    address _to,
    uint256, /* _value */
    bytes memory, /* _data */
    Enum.Operation _operation,
    uint256, /* _safeTxGas */
    uint256, /* _baseGas */
    uint256, /* _gasPrice */
    address, /* _gasToken */
    address payable, /*  _refundReceiver */
    bytes memory _signatures,
    address _msgSender
  ) external override {
    // If operation is delegateCall, to must be MULTI_SEND_CALL_ONLY
    if (_operation == Enum.Operation.DelegateCall) {
      if (_to != MULTI_SEND_CALL_ONLY) {
        revert UnauthorizedDelegateCall(_to);
      }
    }
    // Allow transactions from the entrypoint or emergency caller
    if (_msgSender != ENTRYPOINT && _msgSender != EMERGENCY_CALLER) {
      revert UnauthorizedSender(_msgSender);
    }
    // Validate signature format - only allow pre-approved hash signatures
    if (!_isValidSignatureFormat(_signatures)) {
      revert InvalidSignatureFormat();
    }
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
   * @notice Validates that all signatures are pre-approved hash signatures
   * @param _signatures The signatures to validate
   * @return _isValid Whether all signatures are pre-approved hash signatures
   */
  function _isValidSignatureFormat(bytes memory _signatures) internal pure returns (bool _isValid) {
    // Check if the signatures length is a multiple of 65 bytes
    if (_signatures.length % 65 != 0) {
      return _isValid = false;
    }

    // Check each signature
    for (uint256 i = 0; i < _signatures.length; i += 65) {
      // Get the signature type (last byte of each 65-byte signature)
      uint8 _signatureType = uint8(_signatures[i + 64]);

      // Only allow pre-approved hash signatures (type 0x01)
      if (_signatureType != PRE_VALIDATED_SIGNATURE_TYPE) {
        return _isValid = false;
      }
    }

    _isValid = true;
  }
}
