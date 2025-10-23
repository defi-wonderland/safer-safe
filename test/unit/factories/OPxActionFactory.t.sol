// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Test} from 'forge-std/Test.sol';
import {IActionsBuilder} from 'interfaces/actions-builders/IActionsBuilder.sol';
import {OPxActionFactory} from 'src/contracts/factories/OPxActionFactory.sol';
import {IOPxAction} from 'src/interfaces/actions-builders/IOPxAction.sol';
import {IOPxActionFactory} from 'src/interfaces/factories/IOPxActionFactory.sol';
import {Utils} from 'test/unit/utils/Utils.sol';

contract UnitOPxActionFactorycreateOPxAction is Test, Utils {
  OPxActionFactory public opxActionFactory;
  IOPxAction public auxOPxAction;

  function setUp() external {
    opxActionFactory = new OPxActionFactory();
  }

  function test_WhenCalled(address _opx) external {
    // it should emit OPxActionCreated event with correct parameters
    vm.expectEmit();
    emit IOPxActionFactory.OPxActionCreated(
      _getNextContractDeployedAddress(address(opxActionFactory)), _opx, address(this)
    );

    address _opxAction = opxActionFactory.createOPxAction(_opx);

    // it should deploy an OPxAction
    auxOPxAction = IOPxAction(deployCode('OPxAction', abi.encode(address(opxActionFactory), _opx)));
    assertEq(address(auxOPxAction).code, _opxAction.code);

    // it should match the parameters sent to the constructor
    assertEq(IOPxAction(_opxAction).OPX(), _opx);

    // it should set the parent address in the child contract
    assertEq(IActionsBuilder(_opxAction).PARENT(), address(opxActionFactory));

    // it should store the contract as a factory children
    assertTrue(opxActionFactory.isChild(_opxAction));
  }
}
