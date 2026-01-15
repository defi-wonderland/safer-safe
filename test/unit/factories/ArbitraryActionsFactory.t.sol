// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {ArbitraryActionsFactory} from 'contracts/factories/ArbitraryActionsFactory.sol';
import {Test} from 'forge-std/Test.sol';
import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';
import {IArbitraryActions} from 'interfaces/actions-builders/IArbitraryActions.sol';
import {IArbitraryActionsFactory} from 'interfaces/factories/IArbitraryActionsFactory.sol';
import {Utils} from 'test/unit/utils/Utils.sol';

contract UnitArbitraryActionsFactory is Test, Utils {
  ArbitraryActionsFactory public arbitraryActionsFactory;
  IArbitraryActions public auxArbitraryActions;

  function setUp() external {
    arbitraryActionsFactory = new ArbitraryActionsFactory();
  }

  function test_CreateArbitraryActions_WhenCreatingAnArbitraryActionsContract(
    IArbitraryActions.ArbitraryAction memory _arbitraryActionsA,
    IArbitraryActions.ArbitraryAction memory _arbitraryActionsB
  ) external {
    // it should deploy an ArbitraryActions contract with correct args
    IArbitraryActions.ArbitraryAction[] memory _actions = new IArbitraryActions.ArbitraryAction[](2);
    _actions[0] = _arbitraryActionsA;
    _actions[1] = _arbitraryActionsB;

    // it should emit ArbitraryActionsCreated event with correct parameters
    vm.expectEmit();
    emit IArbitraryActionsFactory
      .ArbitraryActionsCreated(_getNextContractDeployedAddress(address(arbitraryActionsFactory)));

    address _arbitraryActionsContract = arbitraryActionsFactory.createArbitraryActions(_actions);

    // it should deploy an ArbitraryActions contract with correct args
    vm.prank(address(arbitraryActionsFactory));
    auxArbitraryActions = IArbitraryActions(deployCode('ArbitraryActions', abi.encode(_actions)));
    assertEq(address(auxArbitraryActions).code, _arbitraryActionsContract.code);

    // it should match the parameters sent to the constructor
    bytes4 _selectorA = bytes4(keccak256(bytes(_arbitraryActionsA.signature)));
    bytes memory _completeCallDataA = abi.encodePacked(_selectorA, _arbitraryActionsA.data);
    bytes4 _selectorB = bytes4(keccak256(bytes(_arbitraryActionsB.signature)));
    bytes memory _completeCallDataB = abi.encodePacked(_selectorB, _arbitraryActionsB.data);
    IActionsBuilder.Action[] memory _savedActions = IActionsBuilder(_arbitraryActionsContract).getActions();

    // it should match the parameters sent to the constructor
    assertEq(_savedActions.length, 2);
    assertEq(_savedActions[0].target, _arbitraryActionsA.target);
    assertEq(_savedActions[0].data, _completeCallDataA);
    assertEq(_savedActions[0].value, _arbitraryActionsA.value);
    assertEq(_savedActions[1].target, _arbitraryActionsB.target);
    assertEq(_savedActions[1].data, _completeCallDataB);
    assertEq(_savedActions[1].value, _arbitraryActionsB.value);

    // it should save the entire array of actions
    IArbitraryActions.ArbitraryAction[] memory _savedArbitraryActions =
      IArbitraryActions(_arbitraryActionsContract).arbitraryActions();
    assertEq(_savedArbitraryActions.length, 2);
    assertEq(_savedArbitraryActions[0].target, _arbitraryActionsA.target);
    assertEq(_savedArbitraryActions[0].signature, _arbitraryActionsA.signature);
    assertEq(_savedArbitraryActions[0].data, _arbitraryActionsA.data);
    assertEq(_savedArbitraryActions[0].value, _arbitraryActionsA.value);
    assertEq(_savedArbitraryActions[1].target, _arbitraryActionsB.target);
    assertEq(_savedArbitraryActions[1].signature, _arbitraryActionsB.signature);
    assertEq(_savedArbitraryActions[1].data, _arbitraryActionsB.data);

    // it should store the contract as a factory children
    assertTrue(arbitraryActionsFactory.isChild(_arbitraryActionsContract));

    // it should set the parent address in the child contract
    assertEq(IActionsBuilder(_arbitraryActionsContract).PARENT(), address(arbitraryActionsFactory));
  }

  function test_CreateArbitraryAction_WhenCreatingAnArbitraryActionsContractWithASingleArbitraryAction(
    IArbitraryActions.ArbitraryAction memory _arbitraryActions
  ) external {
    IArbitraryActions.ArbitraryAction[] memory _actions = new IArbitraryActions.ArbitraryAction[](1);
    _actions[0] = _arbitraryActions;

    // it should emit ArbitraryActionsCreated event with correct parameters
    vm.expectEmit();
    emit IArbitraryActionsFactory
      .ArbitraryActionsCreated(_getNextContractDeployedAddress(address(arbitraryActionsFactory)));

    // it should deploy an ArbitraryActions contract with that single arbitrary action args
    address _arbitraryActionsContract = arbitraryActionsFactory.createArbitraryAction(_arbitraryActions);

    // it should deploy an ArbitraryActions contract with a single arbitrary action args
    vm.prank(address(arbitraryActionsFactory));
    auxArbitraryActions = IArbitraryActions(deployCode('ArbitraryActions', abi.encode(_actions)));
    assertEq(address(auxArbitraryActions).code, _arbitraryActionsContract.code);

    // it should match the parameters sent to the constructor
    bytes4 _selector = bytes4(keccak256(bytes(_arbitraryActions.signature)));
    bytes memory _completeCallData = abi.encodePacked(_selector, _arbitraryActions.data);
    IActionsBuilder.Action[] memory _savedActions = IActionsBuilder(_arbitraryActionsContract).getActions();
    assertEq(_savedActions.length, 1);
    assertEq(_savedActions[0].target, _arbitraryActions.target);
    assertEq(_savedActions[0].data, _completeCallData);
    assertEq(_savedActions[0].value, _arbitraryActions.value);

    // it should save the entire array of actions
    IArbitraryActions.ArbitraryAction[] memory _savedArbitraryActions =
      IArbitraryActions(_arbitraryActionsContract).arbitraryActions();
    assertEq(_savedArbitraryActions.length, 1);
    assertEq(_savedArbitraryActions[0].target, _arbitraryActions.target);
    assertEq(_savedArbitraryActions[0].signature, _arbitraryActions.signature);
    assertEq(_savedArbitraryActions[0].data, _arbitraryActions.data);
    assertEq(_savedArbitraryActions[0].value, _arbitraryActions.value);

    // it should set the parent address in the child contract
    assertEq(IActionsBuilder(_arbitraryActionsContract).PARENT(), address(arbitraryActionsFactory));

    // it should store the contract as a factory children
    assertTrue(arbitraryActionsFactory.isChild(_arbitraryActionsContract));
  }
}
