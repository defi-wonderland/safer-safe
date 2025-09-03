// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {UnsetEmergencyModeAction} from 'contracts/actions-builders/UnsetEmergencyModeAction.sol';
import {IUnsetEmergencyModeActionFactory} from 'interfaces/factories/IUnsetEmergencyModeActionFactory.sol';

/**
 * @title UnsetEmergencyModeActionFactory
 * @notice Contract that deploys UnsetEmergencyModeAction contracts
 */
contract UnsetEmergencyModeActionFactory is IUnsetEmergencyModeActionFactory {
  // ~~~ FACTORY METHODS ~~~

  /// @inheritdoc IUnsetEmergencyModeActionFactory
  function createUnsetEmergencyModeAction(address _safeEntrypoint) external returns (address _unsetEmergencyModeAction) {
    _unsetEmergencyModeAction = address(new UnsetEmergencyModeAction(_safeEntrypoint));
  }
}
