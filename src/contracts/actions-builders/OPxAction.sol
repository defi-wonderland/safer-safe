// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {IERC20} from 'forge-std/interfaces/IERC20.sol';
import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';
import {IOPxAction} from 'interfaces/actions-builders/IOPxAction.sol';
import {IOPx} from 'interfaces/external/IOPx.sol';

/**
 * @title OPxAction
 * @notice Contract that builds the actions for OPX
 */
contract OPxAction is IOPxAction {
  // ~~~ STORAGE ~~~

  /// @inheritdoc IActionsBuilder
  address public immutable FACTORY;

  /// @inheritdoc IOPxAction
  address public immutable OPX;

  /// @inheritdoc IOPxAction
  address public immutable SAFE;

  // ~~~ CONSTRUCTOR ~~~

  /**
   * @notice Constructor that sets up the OPX contract address
   * @param _factory The factory that deployed the action builder
   * @param _opx The OPX contract address
   * @param _safe The SAFE contract address
   */
  constructor(address _factory, address _opx, address _safe) {
    FACTORY = _factory;
    OPX = _opx;
    SAFE = _safe;
  }

  // ~~~ ACTIONS METHODS ~~~

  /// @inheritdoc IActionsBuilder
  function getActions() external view returns (Action[] memory _actions) {
    uint256 _balance = IERC20(OPX).balanceOf(SAFE);

    _actions = new Action[](1);
    _actions[0] = Action({target: OPX, data: abi.encodeCall(IOPx.downgrade, (_balance)), value: 0});
  }
}
