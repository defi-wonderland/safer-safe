// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import {ISimpleTransfers, SimpleTransfers} from 'contracts/actions-builders/SimpleTransfers.sol';
import {SimpleTransfersFactory} from 'contracts/factories/SimpleTransfersFactory.sol';
import {Test} from 'forge-std/Test.sol';
import {IERC20} from 'forge-std/interfaces/IERC20.sol';

contract UnitSimpleTransfersFactory is Test {
  SimpleTransfersFactory public simpleTransfersFactory;

  function setUp() external {
    simpleTransfersFactory = new SimpleTransfersFactory();
  }

  function test_CreateSimpleTransfersWhenCreatingASimpleTransfersContract(
    ISimpleTransfers.TransferAction memory _transferActionA,
    ISimpleTransfers.TransferAction memory _transferActionB
  ) external {
    ISimpleTransfers.TransferAction[] memory _transferActions = new ISimpleTransfers.TransferAction[](2);
    _transferActions[0] = _transferActionA;
    _transferActions[1] = _transferActionB;

    address _simpleTransfers = simpleTransfersFactory.createSimpleTransfers(_transferActions);

    // it should deploy a SimpleTransfers contract with correct args
    assertEq(type(SimpleTransfers).runtimeCode, _simpleTransfers.code);

    // it should match the parameters sent to the constructor
    ISimpleTransfers.Action[] memory _actions = ISimpleTransfers(_simpleTransfers).getActions();
    assertEq(_actions.length, 2);
    assertEq(_actions[0].target, _transferActionA.token);
    assertEq(_actions[0].data, abi.encodeCall(IERC20.transfer, (_transferActionA.to, _transferActionA.amount)));
    assertEq(_actions[0].value, 0);
    assertEq(_actions[1].target, _transferActionB.token);
    assertEq(_actions[1].data, abi.encodeCall(IERC20.transfer, (_transferActionB.to, _transferActionB.amount)));
    assertEq(_actions[1].value, 0);

    // it should store the contract as children
    assertTrue(simpleTransfersFactory.isChild(_simpleTransfers));
  }

  function test_CreateSimpleTransferWhenCreatingASimpleTransfersContractWithASingleTransferAction(
    address _token,
    address _to,
    uint256 _amount
  ) external {
    ISimpleTransfers.TransferAction memory _transferAction =
      ISimpleTransfers.TransferAction({token: _token, to: _to, amount: _amount});

    address _simpleTransfers = simpleTransfersFactory.createSimpleTransfer(_transferAction);

    // it should deploy a SimpleTransfers contract with a single transfer action
    assertEq(type(SimpleTransfers).runtimeCode, _simpleTransfers.code);

    // it should match the parameters sent to the constructor
    ISimpleTransfers.Action[] memory _actions = ISimpleTransfers(_simpleTransfers).getActions();
    assertEq(_actions.length, 1);
    assertEq(_actions[0].target, _token);
    assertEq(_actions[0].data, abi.encodeCall(IERC20.transfer, (_to, _amount)));
    assertEq(_actions[0].value, 0);

    // it should store the contract as children
    assertTrue(simpleTransfersFactory.isChild(_simpleTransfers));
  }
}
