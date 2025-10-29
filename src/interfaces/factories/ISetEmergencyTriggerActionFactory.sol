// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IFactory} from 'interfaces/factories/IFactory.sol';

/**
 * @title ISetEmergencyTriggerActionFactory
 * @notice Interface for the SetEmergencyTriggerActionFactory contract
 */
interface ISetEmergencyTriggerActionFactory is IFactory {
  // ~~~ FACTORY METHODS ~~~

  /**
   * @notice Creates a SetEmergencyTriggerAction contract
   * @param _emergencyTrigger The emergency trigger address
   * @return _setEmergencyTriggerAction The SetEmergencyTriggerAction contract address
   */
  function createSetEmergencyTriggerAction(address _emergencyTrigger)
    external
    returns (address _setEmergencyTriggerAction);
}
