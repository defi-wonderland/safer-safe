// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Test} from 'forge-std/Test.sol';
import {IERC20} from 'forge-std/interfaces/IERC20.sol';
import {EverclearTokenConversion} from 'src/contracts/actions-builders/EverclearTokenConversion.sol';
import {IActionsBuilder} from 'src/interfaces/actions-builders/IActionsBuilder.sol';
import {IxERC20Lockbox} from 'src/interfaces/external/IxERC20Lockbox.sol';

contract UnitEverclearTokenConversion is Test {
  EverclearTokenConversion public everclearTokenConversion;
  address public clearLockbox = makeAddr('clearLockbox');
  address public next = makeAddr('NEXT');
  address public safe = makeAddr('SAFE');

  function setUp() external {
    everclearTokenConversion = new EverclearTokenConversion(address(0), clearLockbox, next, safe);
  }

  function test_ConstructorWhenCalled() external view {
    // it sets the clear lockbox address
    assertEq(address(everclearTokenConversion.CLEAR_LOCKBOX()), clearLockbox);
    // it sets the NEXT address
    assertEq(address(everclearTokenConversion.NEXT()), next);
    // it sets the SAFE address
    assertEq(address(everclearTokenConversion.SAFE()), safe);
  }

  function test_GetActionsWhenCalled(uint256 _amount) external {
    vm.mockCall(next, abi.encodeWithSelector(IERC20.balanceOf.selector, safe), abi.encode(_amount));
    vm.expectCall(next, abi.encodeWithSelector(IERC20.balanceOf.selector, safe));

    // it returns an action to approve the NEXT amount to be converted
    IActionsBuilder.Action[] memory actions = everclearTokenConversion.getActions();
    assertEq(actions[0].target, address(next));
    assertEq(actions[0].data, abi.encodeCall(IERC20.approve, (address(clearLockbox), _amount)));
    assertEq(actions[0].value, 0);

    // it returns an action to deposit the NEXT amount to be converted
    assertEq(actions[1].target, address(clearLockbox));
    assertEq(actions[1].data, abi.encodeCall(IxERC20Lockbox.deposit, (_amount)));
    assertEq(actions[1].value, 0);
  }
}
