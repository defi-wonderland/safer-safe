// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.29;

import {Test} from 'forge-std/Test.sol';
import {OPxActionFactory} from 'src/contracts/factories/OPxActionFactory.sol';
import {IOPxAction} from 'src/interfaces/actions-builders/IOPxAction.sol';

contract UnitOPxActionFactorycreateOPxAction is Test {
  OPxActionFactory public opxActionFactory;
  IOPxAction public auxOPxAction;

  function setUp() external {
    opxActionFactory = new OPxActionFactory();
  }

  function test_WhenCalled(address _opx, address _safe) external {
    address _opxAction = opxActionFactory.createOPxAction(_opx, _safe);

    // it should deploy an OPxAction
    auxOPxAction = IOPxAction(deployCode('OPxAction', abi.encode(_opx, _safe)));
    assertEq(address(auxOPxAction).code, _opxAction.code);

    // it should match the parameters sent to the constructor
    assertEq(IOPxAction(_opxAction).OPX(), _opx);
    assertEq(IOPxAction(_opxAction).SAFE(), _safe);

    // it should store the contract as a factory children
    assertTrue(opxActionFactory.isChild(_opxAction));
  }
}
