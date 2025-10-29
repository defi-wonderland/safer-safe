// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ActionsBuilder} from 'contracts/actions-builders/ActionsBuilder.sol';
import {IERC20} from 'forge-std/interfaces/IERC20.sol';
import {ISafeManageable} from 'interfaces/ISafeManageable.sol';
import {IEverclearTokenConversion} from 'interfaces/actions-builders/IEverclearTokenConversion.sol';
import {IxERC20Lockbox} from 'interfaces/external/IxERC20Lockbox.sol';

/**
 * @title EverclearTokenConversion
 * @notice Builds the sequence of actions to convert all NEXT held by SAFE into CLEAR via the xERC20 lockbox.
 * @dev Produces two actions:
 *  1) Approve CLEAR_LOCKBOX to spend the NEXT balance of SAFE. The amount approved is the balance of NEXT held by SAFE.
 *  2) Call `IxERC20Lockbox.deposit(amount)` to deposit `NEXT` and mint CLEAR.
 */
contract EverclearTokenConversion is IEverclearTokenConversion, ActionsBuilder {
  // ~~~ STORAGE ~~~

  /// @inheritdoc IEverclearTokenConversion
  IxERC20Lockbox public immutable CLEAR_LOCKBOX;

  /// @inheritdoc IEverclearTokenConversion
  IERC20 public immutable NEXT;

  // ~~~ CONSTRUCTOR ~~~

  /**
   * @notice Initializes the builder with the xERC20 lockbox, the NEXT token, and the SAFE whose balance will be converted.
   * @param _parent The parent that deployed the actions builder
   * @param _lockbox The xERC20 lockbox that accepts NEXT and mints CLEAR
   * @param _next The NEXT ERC20 token to deposit into the lockbox
   */
  constructor(address _parent, address _lockbox, address _next) ActionsBuilder(_parent) {
    CLEAR_LOCKBOX = IxERC20Lockbox(_lockbox);
    NEXT = IERC20(_next);
  }

  // ~~~ ACTIONS METHODS ~~~

  /// @inheritdoc ActionsBuilder
  function getActions() external view override returns (Action[] memory _actions) {
    uint256 _amount = NEXT.balanceOf(address(ISafeManageable(msg.sender).SAFE()));

    _actions = new Action[](2);
    _actions[0] = Action({
      target: address(NEXT), data: abi.encodeCall(IERC20.approve, (address(CLEAR_LOCKBOX), _amount)), value: 0
    });
    _actions[1] =
      Action({target: address(CLEAR_LOCKBOX), data: abi.encodeCall(IxERC20Lockbox.deposit, (_amount)), value: 0});
  }
}
