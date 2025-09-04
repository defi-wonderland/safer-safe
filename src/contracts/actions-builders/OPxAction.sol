// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {ActionsBuilder} from 'contracts/actions-builders/ActionsBuilder.sol';
import {IERC20} from 'forge-std/interfaces/IERC20.sol';
import {IOPxAction} from 'interfaces/actions-builders/IOPxAction.sol';
import {IOPx} from 'interfaces/external/IOPx.sol';

/**
 * @title OPxAction
 * @notice Contract that builds the actions for OPX
 */
contract OPxAction is IOPxAction, ActionsBuilder {
  // ~~~ STORAGE ~~~

  /// @inheritdoc IOPxAction
  address public immutable OPX;

  /// @inheritdoc IOPxAction
  address public immutable SAFE;

  // ~~~ CONSTRUCTOR ~~~

  /**
   * @notice Constructor that sets up the OPX contract address
   * @param _parent The parent that deployed the actions buider
   * @param _opx The OPX contract address
   * @param _safe The SAFE contract address
   */
  constructor(address _parent, address _opx, address _safe) ActionsBuilder(_parent) {
    OPX = _opx;
    SAFE = _safe;
  }

  // ~~~ ACTIONS METHODS ~~~

  /// @inheritdoc ActionsBuilder
  function getActions() external view override returns (Action[] memory _actions) {
    uint256 _balance = IERC20(OPX).balanceOf(SAFE);

    _actions = new Action[](1);
    _actions[0] = Action({target: OPX, data: abi.encodeCall(IOPx.downgrade, (_balance)), value: 0});
  }
}
