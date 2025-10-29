// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';

/**
 * @title IOPxAction
 * @notice Interface for the OPxAction contract
 */
interface IOPxAction is IActionsBuilder {
  /**
   * @notice Returns the OPX contract address
   * @return _opx The OPX contract address
   */
  function OPX() external view returns (address _opx);
}
