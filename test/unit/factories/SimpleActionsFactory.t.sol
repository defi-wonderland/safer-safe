// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {SimpleActionsFactory} from 'contracts/factories/SimpleActionsFactory.sol';
import {Test} from 'forge-std/Test.sol';
import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';
import {ISimpleActions} from 'interfaces/actions-builders/ISimpleActions.sol';
import {ISimpleActionsFactory} from 'interfaces/factories/ISimpleActionsFactory.sol';
import {Utils} from 'test/unit/utils/Utils.sol';

contract UnitSimpleActionsFactory is Test, Utils {
  SimpleActionsFactory public simpleActionsFactory;
  ISimpleActions public auxSimpleActions;

  function setUp() external {
    simpleActionsFactory = new SimpleActionsFactory();
  }

  function test_CreateSimpleActions_WhenCreatingASimpleActionsContract(
    ISimpleActions.SimpleAction memory _simpleActionsA,
    ISimpleActions.SimpleAction memory _simpleActionsB
  ) external {
    // it should deploy a SimpleActions contract with correct args
    ISimpleActions.SimpleAction[] memory _actions = new ISimpleActions.SimpleAction[](2);
    _actions[0] = _simpleActionsA;
    _actions[1] = _simpleActionsB;

    // it should emit SimpleActionsCreated event with correct parameters
    vm.expectEmit();
    emit ISimpleActionsFactory.SimpleActionsCreated(_getNextContractDeployedAddress(address(simpleActionsFactory)));

    address _simpleActionsContract = simpleActionsFactory.createSimpleActions(_actions);

    // it should deploy a SimpleActions contract with correct args
    auxSimpleActions = ISimpleActions(deployCode('SimpleActions', abi.encode(address(simpleActionsFactory), _actions)));
    assertEq(address(auxSimpleActions).code, _simpleActionsContract.code);

    // it should match the parameters sent to the constructor
    bytes4 _selectorA = bytes4(keccak256(bytes(_simpleActionsA.signature)));
    bytes memory _completeCallDataA = abi.encodePacked(_selectorA, _simpleActionsA.data);
    bytes4 _selectorB = bytes4(keccak256(bytes(_simpleActionsB.signature)));
    bytes memory _completeCallDataB = abi.encodePacked(_selectorB, _simpleActionsB.data);
    IActionsBuilder.Action[] memory _savedActions = IActionsBuilder(_simpleActionsContract).getActions();

    // it should match the parameters sent to the constructor
    assertEq(_savedActions.length, 2);
    assertEq(_savedActions[0].target, _simpleActionsA.target);
    assertEq(_savedActions[0].data, _completeCallDataA);
    assertEq(_savedActions[0].value, _simpleActionsA.value);
    assertEq(_savedActions[1].target, _simpleActionsB.target);
    assertEq(_savedActions[1].data, _completeCallDataB);
    assertEq(_savedActions[1].value, _simpleActionsB.value);

    // it should save the entire array of actions
    ISimpleActions.SimpleAction[] memory _savedSimpleActions = ISimpleActions(_simpleActionsContract).simpleActions();
    assertEq(_savedSimpleActions.length, 2);
    assertEq(_savedSimpleActions[0].target, _simpleActionsA.target);
    assertEq(_savedSimpleActions[0].signature, _simpleActionsA.signature);
    assertEq(_savedSimpleActions[0].data, _simpleActionsA.data);
    assertEq(_savedSimpleActions[0].value, _simpleActionsA.value);
    assertEq(_savedSimpleActions[1].target, _simpleActionsB.target);
    assertEq(_savedSimpleActions[1].signature, _simpleActionsB.signature);
    assertEq(_savedSimpleActions[1].data, _simpleActionsB.data);

    // it should store the contract as a factory children
    assertTrue(simpleActionsFactory.isChild(_simpleActionsContract));

    // it should set the parent address in the child contract
    assertEq(IActionsBuilder(_simpleActionsContract).PARENT(), address(simpleActionsFactory));
  }

  function test_CreateSimpleAction_WhenCreatingASimpleActionsContractWithASingleSimpleAction(
    ISimpleActions.SimpleAction memory _simpleActions
  ) external {
    ISimpleActions.SimpleAction[] memory _actions = new ISimpleActions.SimpleAction[](1);
    _actions[0] = _simpleActions;

    // it should emit SimpleActionsCreated event with correct parameters
    vm.expectEmit();
    emit ISimpleActionsFactory.SimpleActionsCreated(_getNextContractDeployedAddress(address(simpleActionsFactory)));

    // it should deploy a SimpleActions contract with that single simple action args
    address _simpleActionsContract = simpleActionsFactory.createSimpleAction(_simpleActions);

    // it should deploy a SimpleActions contract with a single simple action args
    auxSimpleActions = ISimpleActions(deployCode('SimpleActions', abi.encode(address(simpleActionsFactory), _actions)));
    assertEq(address(auxSimpleActions).code, _simpleActionsContract.code);

    // it should match the parameters sent to the constructor
    bytes4 _selector = bytes4(keccak256(bytes(_simpleActions.signature)));
    bytes memory _completeCallData = abi.encodePacked(_selector, _simpleActions.data);
    IActionsBuilder.Action[] memory _savedActions = IActionsBuilder(_simpleActionsContract).getActions();
    assertEq(_savedActions.length, 1);
    assertEq(_savedActions[0].target, _simpleActions.target);
    assertEq(_savedActions[0].data, _completeCallData);
    assertEq(_savedActions[0].value, _simpleActions.value);

    // it should save the entire array of actions
    ISimpleActions.SimpleAction[] memory _savedSimpleActions = ISimpleActions(_simpleActionsContract).simpleActions();
    assertEq(_savedSimpleActions.length, 1);
    assertEq(_savedSimpleActions[0].target, _simpleActions.target);
    assertEq(_savedSimpleActions[0].signature, _simpleActions.signature);
    assertEq(_savedSimpleActions[0].data, _simpleActions.data);
    assertEq(_savedSimpleActions[0].value, _simpleActions.value);

    // it should set the parent address in the child contract
    assertEq(IActionsBuilder(_simpleActionsContract).PARENT(), address(simpleActionsFactory));

    // it should store the contract as a factory children
    assertTrue(simpleActionsFactory.isChild(_simpleActionsContract));
  }
}
