// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

/**
 * @title IOPxActionFactory
 * @notice Interface for the OPxActionFactory contract
 */
interface IOPxActionFactory {
  // ~~~ FACTORY METHODS ~~~

  /**
   * @notice Creates an OPxAction contract
   * @param _opx The OPX contract address
   * @param _safe The SAFE contract address
   * @return _opxAction The OPxAction contract address
   */
  function createOPxAction(address _opx, address _safe) external returns (address _opxAction);
}
