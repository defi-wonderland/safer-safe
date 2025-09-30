// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from 'forge-std/Test.sol';
import {IERC20} from 'forge-std/interfaces/IERC20.sol';
import {OPxAction} from 'src/contracts/actions-builders/OPxAction.sol';
import {ISafeManageable} from 'src/interfaces/ISafeManageable.sol';
import {IActionsBuilder} from 'src/interfaces/actions-builders/IActionsBuilder.sol';
import {IOPx} from 'src/interfaces/external/IOPx.sol';

contract UnitOPxAction is Test {
  uint256 public constant BALANCE = 100;
  OPxAction public opxAction;
  address public opx = makeAddr('opx');

  function setUp() external {
    opxAction = new OPxAction(address(0), opx);
  }

  function test_ConstructorWhenCalled() external view {
    // it sets the OPX address
    assertEq(opxAction.OPX(), opx);
  }

  function test_GetActionsWhenCalled(address _safe) external {
    _mockAndExpect(address(this), abi.encodeWithSelector(ISafeManageable.SAFE.selector), abi.encode(_safe));
    _mockAndExpect(opx, abi.encodeWithSelector(IERC20.balanceOf.selector, _safe), abi.encode(BALANCE));

    // it returns an action to downgrade the OPX SAFE balance
    IActionsBuilder.Action[] memory actions = opxAction.getActions();
    assertEq(actions[0].target, opx);
    assertEq(actions[0].data, abi.encodeCall(IOPx.downgrade, (BALANCE)));
    assertEq(actions[0].value, 0);
  }

  function _mockAndExpect(address _target, bytes memory _call, bytes memory _returnData) internal {
    vm.mockCall(_target, _call, _returnData);
    vm.expectCall(_target, _call);
  }
}
