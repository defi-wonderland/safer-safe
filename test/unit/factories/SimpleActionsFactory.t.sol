// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import {SimpleActions} from 'contracts/actions-builders/SimpleActions.sol';
import {SimpleActionsFactory} from 'contracts/factories/SimpleActionsFactory.sol';
import {Test} from 'forge-std/Test.sol';
import {ISimpleActions} from 'interfaces/actions-builders/ISimpleActions.sol';

contract UnitSimpleActionsFactorycreateSimpleActions is Test {
  SimpleActionsFactory public simpleActionsFactory;

  function setUp() external {
    simpleActionsFactory = new SimpleActionsFactory();
  }

  function test_WhenCalled(ISimpleActions.SimpleAction memory _simpleActions) external {
    ISimpleActions.SimpleAction[] memory _actions = new ISimpleActions.SimpleAction[](1);
    _actions[0] = _simpleActions;

    address _simpleActionsContract = simpleActionsFactory.createSimpleActions(_actions);

    // it should deploy a SimpleActions contract with correct args
    assertEq(type(SimpleActions).runtimeCode, _simpleActionsContract.code);

    // it should match the parameters sent to the constructor
    bytes4 _selector = bytes4(keccak256(bytes(_simpleActions.signature)));
    bytes memory _completeCallData = abi.encodePacked(_selector, _simpleActions.data);
    ISimpleActions.Action[] memory _savedActions = ISimpleActions(_simpleActionsContract).getActions();
    assertEq(_savedActions.length, 1);
    assertEq(_savedActions[0].target, _simpleActions.target);
    assertEq(_savedActions[0].data, _completeCallData);
    assertEq(_savedActions[0].value, _simpleActions.value);

    // it should store the contract in the factory
    assertTrue(simpleActionsFactory.isChild(_simpleActionsContract));
  }
}
