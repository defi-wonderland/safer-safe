// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ChangeSafeGuardAction} from 'contracts/actions-builders/ChangeSafeGuardAction.sol';
import {IChangeSafeGuardActionFactory} from 'interfaces/factories/IChangeSafeGuardActionFactory.sol';

/**
 * @title ChangeSafeGuardActionFactory
 * @notice Contract that deploys ChangeSafeGuardAction contracts
 */
contract ChangeSafeGuardActionFactory is IChangeSafeGuardActionFactory {
  // ~~~ FACTORY METHODS ~~~

  /// @inheritdoc IChangeSafeGuardActionFactory
  function createChangeSafeGuardAction(
    address _safe,
    address _safeGuard
  ) external returns (address _changeSafeGuardAction) {
    _changeSafeGuardAction = address(new ChangeSafeGuardAction(_safe, _safeGuard));
  }
}
