// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

/**
 * @title IChangeSafeGuardActionFactory
 * @notice Interface for the ChangeSafeGuardActionFactory contract
 */
interface IChangeSafeGuardActionFactory {
  // ~~~ FACTORY METHODS ~~~

  /**
   * @notice Creates a ChangeSafeGuardAction contract
   * @param _safe The Safe contract address
   * @param _safeGuard The safe guard contract address
   * @return _changeSafeGuardAction The ChangeSafeGuardAction contract address
   */
  function createChangeSafeGuardAction(
    address _safe,
    address _safeGuard
  ) external returns (address _changeSafeGuardAction);
}
