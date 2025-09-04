// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import {Test} from 'forge-std/Test.sol';

import {IERC20} from 'forge-std/interfaces/IERC20.sol';
import {CappedTokenTransfers} from 'src/contracts/actions-builders/CappedTokenTransfers.sol';
import {ICappedTokenTransfersHub} from 'src/interfaces/action-hubs/ICappedTokenTransfersHub.sol';
import {IActionsBuilder} from 'src/interfaces/actions-builders/IActionsBuilder.sol';

contract UnitCappedTokenTransfers is Test {
  CappedTokenTransfers public cappedTokenTransfers;
  address public token;
  uint256 public amount;
  address public recipient;
  address public hub;

  function setUp() public {
    token = makeAddr('token');
    amount = 100 ether;
    recipient = makeAddr('recipient');
    hub = makeAddr('hub');

    cappedTokenTransfers = new CappedTokenTransfers(token, amount, recipient, hub);
  }

  function test_ConstructorWhenCalled(address _token, uint256 _amount, address _recipient, address _actionHub) external {
    cappedTokenTransfers = new CappedTokenTransfers(_token, _amount, _recipient, _actionHub);

    // it sets the token
    assertEq(cappedTokenTransfers.TOKEN(), _token);
    // it sets the amount
    assertEq(cappedTokenTransfers.AMOUNT(), _amount);
    // it sets the recipient
    assertEq(cappedTokenTransfers.RECIPIENT(), _recipient);
    // it sets the hub
    assertEq(cappedTokenTransfers.HUB(), _actionHub);
  }

  function test_GetActionsWhenCalled() external view {
    IActionsBuilder.Action[] memory actions = cappedTokenTransfers.getActions();

    // it returns an action to update the state
    assertEq(actions[0].target, hub);
    assertEq(actions[0].value, 0);
    assertEq(actions[0].data, abi.encodeWithSelector(ICappedTokenTransfersHub.updateState.selector, token, amount));
    // it returns an action to transfer the tokens
    assertEq(actions[1].target, token);
    assertEq(actions[1].value, 0);
    assertEq(actions[1].data, abi.encodeWithSelector(IERC20.transfer.selector, recipient, amount));
  }
}
