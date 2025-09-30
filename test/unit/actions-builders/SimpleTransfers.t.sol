// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from 'forge-std/Test.sol';
import {IERC20} from 'forge-std/interfaces/IERC20.sol';
import {SimpleTransfers} from 'src/contracts/actions-builders/SimpleTransfers.sol';
import {IActionsBuilder} from 'src/interfaces/actions-builders/IActionsBuilder.sol';
import {ISimpleTransfers} from 'src/interfaces/actions-builders/ISimpleTransfers.sol';

contract UnitSimpleTransfersconstructor is Test {
  SimpleTransfers public simpleTransfers;
  ISimpleTransfers.TransferAction[] public transferActions;

  function setUp() external {
    transferActions.push(ISimpleTransfers.TransferAction({token: address(0), to: address(1), amount: 100}));
    transferActions.push(ISimpleTransfers.TransferAction({token: address(1), to: address(2), amount: 200}));
  }

  function test_WhenRun() external {
    // it should emit the events
    for (uint256 _i; _i < transferActions.length; _i++) {
      vm.expectEmit();
      emit ISimpleTransfers.TransferActionAdded(
        transferActions[_i].token, transferActions[_i].to, transferActions[_i].amount
      );
    }

    simpleTransfers = new SimpleTransfers(address(0), transferActions);

    // it should add the transfer to the actions array with correct values
    IActionsBuilder.Action[] memory _actions = simpleTransfers.getActions();
    for (uint256 _i; _i < transferActions.length; _i++) {
      ISimpleTransfers.TransferAction memory _transferAction = transferActions[_i];

      // it should add the actions to the actions array with correct values
      assertEq(_actions[_i].target, transferActions[_i].token);
      assertEq(_actions[_i].data, abi.encodeCall(IERC20.transfer, (_transferAction.to, _transferAction.amount)));
      assertEq(_actions[_i].value, 0);
    }
  }
}
