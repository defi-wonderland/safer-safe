// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title IChangeSafeGuardAction
 * @notice Interface for the ChangeSafeGuardAction contract
 */
interface IChangeSafeGuardAction {
  // ~~~ STORAGE METHODS ~~~

  /**
   * @notice Gets the Safe contract address
   * @return _safe The Safe contract address
   */
  function SAFE() external view returns (address _safe);

  /**
   * @notice Gets the safe guard contract address
   * @return _safeGuard The safe guard contract address
   */
  function SAFE_GUARD() external view returns (address _safeGuard);
}
