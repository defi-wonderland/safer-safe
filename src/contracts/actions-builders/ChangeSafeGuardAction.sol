// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IGuardManager} from '@safe-smart-account/interfaces/IGuardManager.sol';
import {ActionsBuilder} from 'contracts/actions-builders/ActionsBuilder.sol';
import {IChangeSafeGuardAction} from 'interfaces/actions-builders/IChangeSafeGuardAction.sol';

contract ChangeSafeGuardAction is IChangeSafeGuardAction, ActionsBuilder {
  /// @inheritdoc IChangeSafeGuardAction
  address public immutable SAFE;

  /// @inheritdoc IChangeSafeGuardAction
  address public immutable SAFE_GUARD;

  /**
   * @notice Constructor that sets up the ChangeSafeGuardAction contract
   * @param _parent The parent that deployed the actions builder
   * @param _safe The Safe contract address
   * @param _safeGuard The new safe guard contract address. If the idea is to remove the guard, set it to address(0)
   */
  constructor(address _parent, address _safe, address _safeGuard) ActionsBuilder(_parent) {
    SAFE = _safe;
    SAFE_GUARD = _safeGuard;
  }

  // ~~~ ACTIONS METHODS ~~~

  /// @inheritdoc ActionsBuilder
  function getActions() external view override returns (Action[] memory _actions) {
    _actions = new Action[](1);
    _actions[0] = Action({target: SAFE, data: abi.encodeCall(IGuardManager.setGuard, (SAFE_GUARD)), value: 0});
  }
}
