// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {UnsetEmergencyModeAction} from 'contracts/actions-builders/UnsetEmergencyModeAction.sol';
import {Factory} from 'contracts/factories/Factory.sol';
import {IUnsetEmergencyModeActionFactory} from 'interfaces/factories/IUnsetEmergencyModeActionFactory.sol';

/**
 * @title UnsetEmergencyModeActionFactory
 * @notice Contract that deploys UnsetEmergencyModeAction contracts
 */
contract UnsetEmergencyModeActionFactory is IUnsetEmergencyModeActionFactory, Factory {
  // ~~~ FACTORY METHODS ~~~

  /// @inheritdoc IUnsetEmergencyModeActionFactory
  function createUnsetEmergencyModeAction(address _canonGuard) external returns (address _unsetEmergencyModeAction) {
    _unsetEmergencyModeAction = address(new UnsetEmergencyModeAction(address(this), _canonGuard));

    _children[_unsetEmergencyModeAction] = true;
  }
}
