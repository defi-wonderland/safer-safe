// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.29;

/**
 * @title IOnlyEntrypointGuard
 * @notice Interface for the OnlyEntrypointGuard contract
 */
interface IOnlyEntrypointGuard {
  // ~~~ STORAGE METHODS ~~~

  /**
   * @notice Gets the address of the Safe Entrypoint contract
   * @return _entrypoint The address of the Safe Entrypoint contract
   */
  function ENTRYPOINT() external view returns (address _entrypoint);

  /**
   * @notice Gets the minimum number of signers required for emergency override
   * @return _minSigners The minimum number of signers required
   */
  function MIN_SIGNERS() external view returns (uint256 _minSigners);

  // ~~~ ERRORS ~~~

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
