// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {SetEmergencyTriggerAction} from 'contracts/actions-builders/SetEmergencyTriggerAction.sol';
import {Factory} from 'contracts/factories/Factory.sol';
import {ISetEmergencyTriggerActionFactory} from 'interfaces/factories/ISetEmergencyTriggerActionFactory.sol';

/**
 * @title SetEmergencyTriggerActionFactory
 * @notice Contract that deploys SetEmergencyTriggerAction contracts
 */
contract SetEmergencyTriggerActionFactory is ISetEmergencyTriggerActionFactory, Factory {
  // ~~~ FACTORY METHODS ~~~

  /// @inheritdoc ISetEmergencyTriggerActionFactory
  function createSetEmergencyTriggerAction(address _emergencyTrigger)
    external
    returns (address _setEmergencyTriggerAction)
  {
    _setEmergencyTriggerAction = address(new SetEmergencyTriggerAction(address(this), _emergencyTrigger));

    _children[_setEmergencyTriggerAction] = true;

    emit SetEmergencyTriggerActionCreated(_setEmergencyTriggerAction, _emergencyTrigger);
  }
}
