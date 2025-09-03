// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import {SimpleActions} from 'contracts/actions-builders/SimpleActions.sol';
import {SimpleActionsFactory} from 'contracts/factories/SimpleActionsFactory.sol';
import {Test} from 'forge-std/Test.sol';
import {ISimpleActions} from 'interfaces/actions-builders/ISimpleActions.sol';

contract UnitSimpleActionsFactory is Test {
  SimpleActionsFactory public simpleActionsFactory;

  function setUp() external {
    simpleActionsFactory = new SimpleActionsFactory();
  }

  function test_CreateSimpleActionsWhenCreatingASimpleActionsContract(
    ISimpleActions.SimpleAction memory _simpleActionsA,
    ISimpleActions.SimpleAction memory _simpleActionsB
  ) external {
    // it should deploy a SimpleActions contract with correct args
    ISimpleActions.SimpleAction[] memory _actions = new ISimpleActions.SimpleAction[](2);
    _actions[0] = _simpleActionsA;
    _actions[1] = _simpleActionsB;

    address _simpleActionsContract = simpleActionsFactory.createSimpleActions(_actions);

    // it should deploy a SimpleActions contract with correct args
    assertEq(type(SimpleActions).runtimeCode, _simpleActionsContract.code);

    // it should match the parameters sent to the constructor
    bytes4 _selectorA = bytes4(keccak256(bytes(_simpleActionsA.signature)));
    bytes memory _completeCallDataA = abi.encodePacked(_selectorA, _simpleActionsA.data);
    bytes4 _selectorB = bytes4(keccak256(bytes(_simpleActionsB.signature)));
    bytes memory _completeCallDataB = abi.encodePacked(_selectorB, _simpleActionsB.data);
    ISimpleActions.Action[] memory _savedActions = ISimpleActions(_simpleActionsContract).getActions();

    // it should match the parameters sent to the constructor
    assertEq(_savedActions.length, 2);
    assertEq(_savedActions[0].target, _simpleActionsA.target);
    assertEq(_savedActions[0].data, _completeCallDataA);
    assertEq(_savedActions[0].value, _simpleActionsA.value);
    assertEq(_savedActions[1].target, _simpleActionsB.target);
    assertEq(_savedActions[1].data, _completeCallDataB);
    assertEq(_savedActions[1].value, _simpleActionsB.value);

    // it should store the contract in the factory
    assertTrue(simpleActionsFactory.isChild(_simpleActionsContract));
  }

  function test_CreateSimpleActionWhenCreatingASimpleActionsContractWithASingleSimpleAction(
    ISimpleActions.SimpleAction memory _simpleActions
  ) external {
    ISimpleActions.SimpleAction[] memory _actions = new ISimpleActions.SimpleAction[](1);
    _actions[0] = _simpleActions;
    // it should deploy a SimpleActions contract with that single simple action args
    address _simpleActionsContract = simpleActionsFactory.createSimpleAction(_simpleActions);

    // it should deploy a SimpleActions contract with a single simple action args
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
