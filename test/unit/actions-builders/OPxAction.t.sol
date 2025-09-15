// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from 'forge-std/Test.sol';
import {IERC20} from 'forge-std/interfaces/IERC20.sol';
import {OPxAction} from 'src/contracts/actions-builders/OPxAction.sol';
import {IActionsBuilder} from 'src/interfaces/actions-builders/IActionsBuilder.sol';
import {IOPx} from 'src/interfaces/external/IOPx.sol';

contract UnitOPxAction is Test {
  uint256 public constant BALANCE = 100;
  OPxAction public opxAction;
  address public opx = makeAddr('opx');
  address public safe = makeAddr('safe');

  function setUp() external {
    opxAction = new OPxAction(address(0), opx, safe);
  }

  function test_ConstructorWhenCalled() external view {
    // it sets the OPX address
    assertEq(opxAction.OPX(), opx);
    // it sets the SAFE address
    assertEq(opxAction.SAFE(), safe);
  }

  function test_GetActionsWhenCalled() external {
    vm.mockCall(opx, abi.encodeWithSelector(IERC20.balanceOf.selector, safe), abi.encode(BALANCE));
    vm.expectCall(opx, abi.encodeWithSelector(IERC20.balanceOf.selector, safe));

    // it returns an action to downgrade the OPX SAFE balance
    IActionsBuilder.Action[] memory actions = opxAction.getActions();
    assertEq(actions[0].target, opx);
    assertEq(actions[0].data, abi.encodeCall(IOPx.downgrade, (BALANCE)));
    assertEq(actions[0].value, 0);
  }
}
