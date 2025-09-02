// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IGuardManager} from '@safe-smart-account/interfaces/IGuardManager.sol';
import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';
import {IChangeSafeGuardAction} from 'interfaces/actions-builders/IChangeSafeGuardAction.sol';

contract ChangeSafeGuardAction is IChangeSafeGuardAction {
  /// @inheritdoc IChangeSafeGuardAction
  address public immutable SAFE;

  /// @inheritdoc IChangeSafeGuardAction
  address public immutable SAFE_GUARD;

  /**
   * @notice Constructor that sets up the ChangeSafeGuardAction contract
   * @param _safe The Safe contract address
   * @param _safeGuard The new safe guard contract address. If the idea is to remove the guard, set it to address(0)
   */
  constructor(address _safe, address _safeGuard) {
    SAFE = _safe;
    SAFE_GUARD = _safeGuard;
  }

  // ~~~ ACTIONS METHODS ~~~

  /// @inheritdoc IActionsBuilder
  function getActions() external view returns (Action[] memory _actions) {
    _actions = new Action[](1);
    _actions[0] = Action({target: SAFE, data: abi.encodeCall(IGuardManager.setGuard, (SAFE_GUARD)), value: 0});
  }
}
