// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ChangeSafeGuardAction} from 'contracts/actions-builders/ChangeSafeGuardAction.sol';
import {Factory} from 'contracts/factories/Factory.sol';
import {IChangeSafeGuardActionFactory} from 'interfaces/factories/IChangeSafeGuardActionFactory.sol';

/**
 * @title ChangeSafeGuardActionFactory
 * @notice Contract that deploys ChangeSafeGuardAction contracts
 */
contract ChangeSafeGuardActionFactory is IChangeSafeGuardActionFactory, Factory {
  // ~~~ FACTORY METHODS ~~~

  /// @inheritdoc IChangeSafeGuardActionFactory
  function createChangeSafeGuardAction(address _safeGuard) external returns (address _changeSafeGuardAction) {
    _changeSafeGuardAction = address(new ChangeSafeGuardAction(address(this), _safeGuard));

    _children[_changeSafeGuardAction] = true;
  }
}
