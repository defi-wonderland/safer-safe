// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {SetEmergencyTriggerAction} from 'contracts/actions-builders/SetEmergencyTriggerAction.sol';
import {ISetEmergencyTriggerActionFactory} from 'interfaces/factories/ISetEmergencyTriggerActionFactory.sol';

/**
 * @title SetEmergencyTriggerActionFactory
 * @notice Contract that deploys SetEmergencyTriggerAction contracts
 */
contract SetEmergencyTriggerActionFactory is ISetEmergencyTriggerActionFactory {
  // ~~~ FACTORY METHODS ~~~

  /// @inheritdoc ISetEmergencyTriggerActionFactory
  function createSetEmergencyTriggerAction(
    address _safeEntrypoint,
    address _emergencyTrigger
  ) external returns (address _setEmergencyTriggerAction) {
    _setEmergencyTriggerAction = address(new SetEmergencyTriggerAction(_safeEntrypoint, _emergencyTrigger));
  }
}
