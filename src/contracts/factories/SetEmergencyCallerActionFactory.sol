// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {SetEmergencyCallerAction} from 'contracts/actions-builders/SetEmergencyCallerAction.sol';
import {Factory} from 'contracts/factories/Factory.sol';
import {ISetEmergencyCallerActionFactory} from 'interfaces/factories/ISetEmergencyCallerActionFactory.sol';

/**
 * @title SetEmergencyCallerActionFactory
 * @notice Contract that deploys SetEmergencyCallerAction contracts
 */
contract SetEmergencyCallerActionFactory is ISetEmergencyCallerActionFactory, Factory {
  // ~~~ FACTORY METHODS ~~~

  /// @inheritdoc ISetEmergencyCallerActionFactory
  function createSetEmergencyCallerAction(
    address _canonGuard,
    address _emergencyCaller
  ) external returns (address _setEmergencyCallerAction) {
    _setEmergencyCallerAction = address(new SetEmergencyCallerAction(address(this), _canonGuard, _emergencyCaller));

    _children[_setEmergencyCallerAction] = true;
  }
}
