// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.29;

/**
 * @title IOnlyEntrypointGuard
 * @notice Interface for the OnlyEntrypointGuard contract
 */
interface IOnlyEntrypointGuard {
  // ~~~ STORAGE METHODS ~~~

  /**
   * @notice Gets the signature type constant for pre-approved hash signatures
   * @return _preValidatedSignatureType The signature type constant for pre-approved hash signatures
   */
  function PRE_VALIDATED_SIGNATURE_TYPE() external view returns (uint256 _preValidatedSignatureType);

  /**
   * @notice Gets the address of the Safe Entrypoint contract
   * @return _entrypoint The address of the Safe Entrypoint contract
   */
  function ENTRYPOINT() external view returns (address _entrypoint);

  /**
   * @notice Gets the address of the emergency caller
   * @return _emergencyCaller The address of the emergency caller (can be contract or EOA)
   */
  function EMERGENCY_CALLER() external view returns (address _emergencyCaller);

  /**
   * @notice Gets the address of the MultiSendCallOnly contract
   * @return _multiSendCallOnly The address of the MultiSendCallOnly contract
   */
  function MULTI_SEND_CALL_ONLY() external view returns (address _multiSendCallOnly);

  // ~~~ ERRORS ~~~

  /**
   * @notice Thrown when the signature format is invalid
   */
  error InvalidSignatureFormat();

  /**
   * @notice Thrown when a delegate call is attempted to an unauthorized address
   * @param _target The unauthorized target address
   */
  error UnauthorizedDelegateCall(address _target);

  /**
   * @notice Thrown when a transaction is attempted by an unauthorized sender
   * @param _sender The unauthorized sender address
   */
  error UnauthorizedSender(address _sender);

  /**
   * @notice Thrown when the caller is not the entrypoint
   */
  error CallerNotEntrypoint();

  /**
   * @notice Thrown when the signer count is insufficient
   */
  error InsufficientSigners();
}
