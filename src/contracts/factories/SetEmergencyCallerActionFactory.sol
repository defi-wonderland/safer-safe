// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {SetEmergencyCallerAction} from 'contracts/actions-builders/SetEmergencyCallerAction.sol';
import {ISetEmergencyCallerActionFactory} from 'interfaces/factories/ISetEmergencyCallerActionFactory.sol';

/**
 * @title SetEmergencyCallerActionFactory
 * @notice Contract that deploys SetEmergencyCallerAction contracts
 */
contract SetEmergencyCallerActionFactory is ISetEmergencyCallerActionFactory {
  // ~~~ FACTORY METHODS ~~~

  /// @inheritdoc ISetEmergencyCallerActionFactory
  function createSetEmergencyCallerAction(
    address _safeEntrypoint,
    address _emergencyCaller
  ) external returns (address _setEmergencyCallerAction) {
    _setEmergencyCallerAction = address(new SetEmergencyCallerAction(_safeEntrypoint, _emergencyCaller));
  }
}
