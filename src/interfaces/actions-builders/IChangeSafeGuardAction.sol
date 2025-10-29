// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';

/**
 * @title IChangeSafeGuardAction
 * @notice Interface for the ChangeSafeGuardAction contract
 */
interface IChangeSafeGuardAction is IActionsBuilder {
  /**
   * @notice Gets the safe guard contract address
   * @return _safeGuard The safe guard contract address
   */
  function SAFE_GUARD() external view returns (address _safeGuard);
}
