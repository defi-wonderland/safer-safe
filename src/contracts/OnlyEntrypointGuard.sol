// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IOnlyEntrypointGuard} from 'interfaces/IOnlyEntrypointGuard.sol';

import {BaseTransactionGuard} from '@safe-smart-account/base/GuardManager.sol';
import {SignatureDecoder} from '@safe-smart-account/common/SignatureDecoder.sol';
import {Enum} from '@safe-smart-account/libraries/Enum.sol';

/**
 * @title OnlyEntrypointGuard
 * @notice Guard that ensures transactions are either executed through the entrypoint or by an emergency caller
 */
contract OnlyEntrypointGuard is BaseTransactionGuard, SignatureDecoder, IOnlyEntrypointGuard {
  /// @inheritdoc IOnlyEntrypointGuard
  uint8 public constant APPROVED_HASH_SIGNATURE_TYPE = 1;

  /// @inheritdoc IOnlyEntrypointGuard
  address public immutable ENTRYPOINT;

  /// @inheritdoc IOnlyEntrypointGuard
  address public immutable EMERGENCY_CALLER;

  /// @inheritdoc IOnlyEntrypointGuard
  address public immutable MULTI_SEND_CALL_ONLY;

  /**
   * @notice Constructor that sets up the guard
   * @param _entrypoint The address of the SafeEntrypoint contract
   * @param _emergencyCaller The address of the emergency caller (can be a multisig or EOA)
   * @param _multiSendCallOnly The address of the MultiSendCallOnly contract
   */
  constructor(address _entrypoint, address _emergencyCaller, address _multiSendCallOnly) {
    ENTRYPOINT = _entrypoint;
    EMERGENCY_CALLER = _emergencyCaller;
    MULTI_SEND_CALL_ONLY = _multiSendCallOnly;
  }

  /**
   * @notice Fallback to avoid issues in case of a Safe upgrade
   * @dev The expected check method might change and then the Safe would be locked
   */
  // solhint-disable-next-line payable-fallback
  fallback() external {}

  /**
   * @notice Checks if a transaction is allowed to be executed before execution
   * @param _to The address to which the transaction is intended
   * @param _operation The type of operation of the transaction
   * @param _signatures The signatures of the transaction
   * @param _msgSender The address of the message sender
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
  ) external view override {
    // Allow transactions from the entrypoint or emergency caller
    if (_msgSender != ENTRYPOINT && _msgSender != EMERGENCY_CALLER) {
      revert UnauthorizedSender(_msgSender);
    }

    // If operation is delegateCall, to must be MULTI_SEND_CALL_ONLY
    if (_operation == Enum.Operation.DelegateCall) {
      if (_to != MULTI_SEND_CALL_ONLY) {
        revert UnauthorizedDelegateCall(_to);
      }
    }

    // Validate signature type – only allow approved hash signatures
    if (!_isValidSignatureType(_signatures)) {
      revert InvalidSignatureType();
    }
  }

  /**
   * @notice Checks if a transaction is allowed to be executed after execution
   * @dev No post-execution checks needed
   */
  function checkAfterExecution(bytes32, /* _hash */ bool /* _success */ ) external pure override {}

  /**
   * @notice Validates that all signatures are approved hash signatures
   * @param _signatures The signatures to validate
   * @return _isValid Whether all signatures are approved hash signatures
   */
  function _isValidSignatureType(bytes memory _signatures) internal pure returns (bool _isValid) {
    // Check each 65-byte signature
    uint256 _signaturesAmount = _signatures.length / 65;
    uint8 _signatureType;
    for (uint256 _i; _i < _signaturesAmount; ++_i) {
      // Get the signature type (last byte of each 65-byte signature)
      (_signatureType,,) = signatureSplit(_signatures, _i);

      // Only allow approved hash signatures (type 1)
      if (_signatureType != APPROVED_HASH_SIGNATURE_TYPE) {
        return _isValid = false;
      }
    }

    _isValid = true;
  }
}
