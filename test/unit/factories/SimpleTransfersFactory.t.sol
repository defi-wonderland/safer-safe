// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import {ISimpleTransfers, SimpleTransfers} from 'contracts/actions-builders/SimpleTransfers.sol';
import {SimpleTransfersFactory} from 'contracts/factories/SimpleTransfersFactory.sol';
import {Test} from 'forge-std/Test.sol';
import {IERC20} from 'forge-std/interfaces/IERC20.sol';

contract UnitSimpleTransfersFactorycreateSimpleTransfers is Test {
  SimpleTransfersFactory public simpleTransfersFactory;
  ISimpleTransfers public auxSimpleTransfers;

  function setUp() external {
    simpleTransfersFactory = new SimpleTransfersFactory();
  }

  function test_WhenCalled(address _token, address _to, uint256 _amount) external {
    ISimpleTransfers.TransferAction[] memory _transferActions = new ISimpleTransfers.TransferAction[](1);
    _transferActions[0] = ISimpleTransfers.TransferAction({token: _token, to: _to, amount: _amount});

    address _simpleTransfers = simpleTransfersFactory.createSimpleTransfers(_transferActions);

    // it should deploy a SimpleTransfers contract with correct args
    auxSimpleTransfers =
      ISimpleTransfers(deployCode('SimpleTransfers', abi.encode(address(simpleTransfersFactory), _transferActions)));
    assertEq(address(auxSimpleTransfers).code, _simpleTransfers.code);

    // it should match the parameters sent to the constructor
    ISimpleTransfers.Action[] memory _actions = ISimpleTransfers(_simpleTransfers).getActions();
    assertEq(_actions.length, 1);
    assertEq(_actions[0].target, _token);
    assertEq(_actions[0].data, abi.encodeCall(IERC20.transfer, (_to, _amount)));
    assertEq(_actions[0].value, 0);

    assertEq(ISimpleTransfers(_simpleTransfers).FACTORY(), address(simpleTransfersFactory));

    // it should store the contract in the factory
    assertTrue(simpleTransfersFactory.isChild(_simpleTransfers));
  }
}
