// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IFactory} from 'interfaces/factories/IFactory.sol';

/**
 * @title IChangeSafeGuardActionFactory
 * @notice Interface for the ChangeSafeGuardActionFactory contract
 */
interface IChangeSafeGuardActionFactory is IFactory {
  // ~~~ FACTORY METHODS ~~~

  /**
   * @notice Creates a ChangeSafeGuardAction contract
   * @param _safeGuard The safe guard contract address
   * @return _changeSafeGuardAction The ChangeSafeGuardAction contract address
   */
  function createChangeSafeGuardAction(address _safeGuard) external returns (address _changeSafeGuardAction);
}
