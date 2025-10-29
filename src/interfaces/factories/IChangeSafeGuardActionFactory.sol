// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title IChangeSafeGuardActionFactory
 * @notice Interface for the ChangeSafeGuardActionFactory contract
 */
interface IChangeSafeGuardActionFactory {
  // ~~~ EVENTS ~~~

  /**
   * @notice Emitted when a new ChangeSafeGuardAction contract is created
   * @param _changeSafeGuardAction The address of the created ChangeSafeGuardAction contract
   * @param _safeGuard The safe guard contract address
   */
  event ChangeSafeGuardActionCreated(address indexed _changeSafeGuardAction, address indexed _safeGuard);

  // ~~~ FACTORY METHODS ~~~

  /**
   * @notice Creates a ChangeSafeGuardAction contract
   * @param _safeGuard The safe guard contract address
   * @return _changeSafeGuardAction The ChangeSafeGuardAction contract address
   */
  function createChangeSafeGuardAction(address _safeGuard) external returns (address _changeSafeGuardAction);
}
