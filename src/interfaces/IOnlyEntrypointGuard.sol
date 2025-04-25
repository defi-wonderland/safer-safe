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
   * @notice Gets the address of the emergency multisig contract
   * @return _emergencyMultisig The address of the emergency multisig contract
   */
  function EMERGENCY_MULTISIG() external view returns (address _emergencyMultisig);

  // ~~~ ERRORS ~~~

  /**
   * @notice Thrown when the signature format is invalid
   */
  error InvalidSignatureFormat();

  /**
   * @notice Thrown when the transaction is not allowed
   */
  error TransactionNotAllowed();

  /**
   * @notice Thrown when the caller is not the entrypoint
   */
  error CallerNotEntrypoint();

  /**
   * @notice Thrown when the signer count is insufficient
   */
  error InsufficientSigners();
}
